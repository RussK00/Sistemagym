import bcrypt from 'bcrypt';
import { query } from '../config/db.js';

// ─── Cuentas de recepcionista (HU-13) ────────────────────────────────────────

// GET /api/configuracion/recepcionistas — listar las cuentas de recepcionista
export async function getRecepcionistas(req, res) {
  try {
    const r = await query(
      `SELECT id_usuario, nombre, correo, activo, fecha_creacion
         FROM usuarios
        WHERE rol = 'recepcionista'
        ORDER BY id_usuario DESC`);
    return res.json(r.rows);
  } catch (err) {
    console.error('Error getRecepcionistas:', err.message);
    return res.status(500).json({ error: 'Error al obtener las cuentas.' });
  }
}

// POST /api/configuracion/recepcionistas — crear una cuenta de recepcionista
// Body: { nombre, correo, password }
export async function crearRecepcionista(req, res) {
  const { nombre, correo, password } = req.body;
  if (!nombre || !correo || !password) {
    return res.status(400).json({ error: 'Nombre, correo y contraseña son obligatorios.' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'La contraseña debe tener al menos 6 caracteres.' });
  }
  try {
    const existe = await query('SELECT id_usuario FROM usuarios WHERE correo = $1',
      [correo.trim().toLowerCase()]);
    if (existe.rows.length > 0) {
      return res.status(409).json({ error: 'Ya existe una cuenta con ese correo.' });
    }
    const hash = await bcrypt.hash(password, 10);
    const r = await query(
      `INSERT INTO usuarios (nombre, correo, contrasena_hash, rol, activo)
       VALUES ($1, $2, $3, 'recepcionista', TRUE)
       RETURNING id_usuario, nombre, correo, activo, fecha_creacion`,
      [nombre.trim(), correo.trim().toLowerCase(), hash]);
    return res.status(201).json(r.rows[0]);
  } catch (err) {
    console.error('Error crearRecepcionista:', err.message);
    return res.status(500).json({ error: 'Error al crear la cuenta.' });
  }
}

// PATCH /api/configuracion/recepcionistas/:id/estado — activar / desactivar
export async function toggleRecepcionista(req, res) {
  const { id } = req.params;
  try {
    const r = await query(
      `UPDATE usuarios SET activo = NOT activo
        WHERE id_usuario = $1 AND rol = 'recepcionista'
        RETURNING id_usuario, nombre, correo, activo, fecha_creacion`, [id]);
    if (r.rows.length === 0) {
      return res.status(404).json({ error: 'Cuenta no encontrada.' });
    }
    return res.json(r.rows[0]);
  } catch (err) {
    console.error('Error toggleRecepcionista:', err.message);
    return res.status(500).json({ error: 'Error al cambiar el estado.' });
  }
}

// DELETE /api/configuracion/recepcionistas/:id — eliminar una cuenta
export async function eliminarRecepcionista(req, res) {
  const { id } = req.params;
  try {
    const del = await query(
      `DELETE FROM usuarios WHERE id_usuario = $1 AND rol = 'recepcionista'
       RETURNING id_usuario`, [id]);
    if (del.rows.length === 0) {
      return res.status(404).json({ error: 'Cuenta no encontrada.' });
    }
    return res.json({ ok: true });
  } catch (err) {
    // 23503 = violación de llave foránea (la cuenta registró asistencias/pagos/ventas)
    if (err.code === '23503') {
      return res.status(409).json({
        error: 'No se puede eliminar: la cuenta tiene registros asociados (asistencias, pagos o ventas). Desactívala en su lugar.',
      });
    }
    console.error('Error eliminarRecepcionista:', err.message);
    return res.status(500).json({ error: 'Error al eliminar la cuenta.' });
  }
}

// GET /api/configuracion — obtener la configuración de alertas
export async function getConfiguracion(req, res) {
  try {
    const result = await query(
      'SELECT dias_anticipacion, notificaciones_activas FROM configuracion WHERE id = 1');
    if (result.rows.length === 0) {
      // Si no existe, devolver los valores por defecto
      return res.json({ dias_anticipacion: 3, notificaciones_activas: true });
    }
    return res.json(result.rows[0]);
  } catch (err) {
    console.error('Error getConfiguracion:', err.message);
    return res.status(500).json({ error: 'Error al obtener la configuración.' });
  }
}

// PUT /api/configuracion — actualizar la configuración (solo admin)
// Body: { dias_anticipacion, notificaciones_activas }
export async function updateConfiguracion(req, res) {
  const { dias_anticipacion, notificaciones_activas } = req.body;

  if (dias_anticipacion == null || dias_anticipacion < 1) {
    return res.status(400).json({ error: 'Los días de anticipación deben ser al menos 1.' });
  }

  try {
    const result = await query(`
      INSERT INTO configuracion (id, dias_anticipacion, notificaciones_activas)
      VALUES (1, $1, $2)
      ON CONFLICT (id) DO UPDATE
        SET dias_anticipacion = $1, notificaciones_activas = $2
      RETURNING dias_anticipacion, notificaciones_activas
    `, [dias_anticipacion, notificaciones_activas ?? true]);

    return res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updateConfiguracion:', err.message);
    return res.status(500).json({ error: 'Error al guardar la configuración.' });
  }
}
