import bcrypt from 'bcrypt';
import { pool, query } from '../config/db.js';

// GET /api/socios — listar todos los socios
export async function getSocios(req, res) {
  try {
    const result = await query(
      `SELECT id_socio, nombres, apellidos, dni, telefono, correo,
              fecha_registro, estado, foto_url
       FROM socios
       ORDER BY id_socio DESC`
    );
    return res.json(result.rows);
  } catch (err) {
    console.error('Error getSocios:', err.message);
    return res.status(500).json({ error: 'Error al obtener los socios.' });
  }
}

// POST /api/socios — crear un socio nuevo
// Además crea su cuenta de acceso a la app (usuario = correo, contraseña inicial = DNI).
export async function createSocio(req, res) {
  const { nombres, apellidos, dni, telefono, correo } = req.body;

  if (!nombres || !apellidos || !dni) {
    return res.status(400).json({ error: 'Nombres, apellidos y DNI son obligatorios.' });
  }
  if (!correo || !correo.trim()) {
    return res.status(400).json({ error: 'El correo es obligatorio (será el usuario de acceso del socio).' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // DNI único
    const dniExiste = await client.query('SELECT id_socio FROM socios WHERE dni = $1', [dni.trim()]);
    if (dniExiste.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Ya existe un socio con ese DNI.' });
    }

    // Correo único entre usuarios (no puede chocar con otra cuenta)
    const correoExiste = await client.query('SELECT id_usuario FROM usuarios WHERE correo = $1', [correo.trim().toLowerCase()]);
    if (correoExiste.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Ya existe una cuenta con ese correo.' });
    }

    // 1. Crear el socio
    const socioRes = await client.query(
      `INSERT INTO socios (nombres, apellidos, dni, telefono, correo, estado)
       VALUES ($1, $2, $3, $4, $5, 'activo')
       RETURNING id_socio, nombres, apellidos, dni, telefono, correo, fecha_registro, estado, foto_url`,
      [nombres.trim(), apellidos.trim(), dni.trim(), telefono?.trim() ?? '', correo.trim()]
    );
    const socio = socioRes.rows[0];

    // 2. Crear su cuenta de acceso (contraseña inicial = DNI)
    const hash = await bcrypt.hash(dni.trim(), 10);
    await client.query(
      `INSERT INTO usuarios (id_socio, nombre, correo, contrasena_hash, rol, activo)
       VALUES ($1, $2, $3, $4, 'socio', TRUE)`,
      [socio.id_socio, `${nombres.trim()} ${apellidos.trim()}`, correo.trim().toLowerCase(), hash]
    );

    await client.query('COMMIT');

    // Devolver el socio + info de acceso para que el recepcionista la comunique
    return res.status(201).json({
      ...socio,
      acceso: { usuario: correo.trim().toLowerCase(), passwordInicial: dni.trim() },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error createSocio:', err.message);
    return res.status(500).json({ error: 'Error al crear el socio.' });
  } finally {
    client.release();
  }
}

// PUT /api/socios/:id — editar un socio
export async function updateSocio(req, res) {
  const { id } = req.params;
  const { nombres, apellidos, dni, telefono, correo } = req.body;

  if (!nombres || !apellidos || !dni) {
    return res.status(400).json({ error: 'Nombres, apellidos y DNI son obligatorios.' });
  }

  try {
    // DNI duplicado en OTRO socio
    const dup = await query('SELECT id_socio FROM socios WHERE dni = $1 AND id_socio <> $2', [dni.trim(), id]);
    if (dup.rows.length > 0) {
      return res.status(409).json({ error: 'Ya existe otro socio con ese DNI.' });
    }

    const result = await query(
      `UPDATE socios
       SET nombres = $1, apellidos = $2, dni = $3, telefono = $4, correo = $5
       WHERE id_socio = $6
       RETURNING id_socio, nombres, apellidos, dni, telefono, correo, fecha_registro, estado, foto_url`,
      [nombres.trim(), apellidos.trim(), dni.trim(), telefono?.trim() ?? '', correo?.trim() ?? '', id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Socio no encontrado.' });
    }
    return res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updateSocio:', err.message);
    return res.status(500).json({ error: 'Error al actualizar el socio.' });
  }
}

// PATCH /api/socios/:id/estado — activar / desactivar
// Sincroniza el estado del socio con su cuenta de acceso (usuarios.activo).
// Si el socio se da de baja, su login también se desactiva (y viceversa).
export async function toggleEstado(req, res) {
  const { id } = req.params;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Estado actual del socio
    const cur = await client.query('SELECT estado FROM socios WHERE id_socio = $1', [id]);
    if (cur.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Socio no encontrado.' });
    }

    // 2. Si se va a DESACTIVAR, no permitir si tiene una membresía vigente.
    if (cur.rows[0].estado === 'activo') {
      const mem = await client.query(`
        SELECT to_char(fecha_vencimiento, 'DD/MM/YYYY') AS venc
        FROM membresias
        WHERE id_socio = $1 AND estado <> 'suspendida'
          AND fecha_vencimiento >= (NOW() AT TIME ZONE 'America/Lima')::date
        ORDER BY fecha_vencimiento DESC LIMIT 1
      `, [id]);
      if (mem.rows.length > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({
          error: `No puedes desactivar a este socio: tiene una membresía vigente (vence el ${mem.rows[0].venc}). Espera a que venza o suspéndela primero.`,
        });
      }
    }

    // 3. Cambiar el estado del socio
    const result = await client.query(
      `UPDATE socios
       SET estado = CASE WHEN estado = 'activo' THEN 'inactivo' ELSE 'activo' END
       WHERE id_socio = $1
       RETURNING id_socio, nombres, apellidos, dni, telefono, correo, fecha_registro, estado, foto_url`,
      [id]
    );
    const socio = result.rows[0];

    // 4. Sincronizar su cuenta de acceso: activo solo si el socio está activo
    await client.query(
      `UPDATE usuarios SET activo = $1 WHERE id_socio = $2`,
      [socio.estado === 'activo', id]
    );

    await client.query('COMMIT');
    return res.json(socio);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error toggleEstado:', err.message);
    return res.status(500).json({ error: 'Error al cambiar el estado.' });
  } finally {
    client.release();
  }
}
