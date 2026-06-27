import { query } from '../config/db.js';

// GET /api/asistencia/hoy — ingresos registrados el día de hoy
export async function getIngresosHoy(req, res) {
  try {
    const result = await query(`
      SELECT a.id_asistencia, a.id_socio,
             s.nombres || ' ' || s.apellidos AS nombre_socio,
             a.fecha_hora_ingreso,
             (SELECT p.nombre FROM membresias m
              JOIN planes p ON p.id_plan = m.id_plan
              WHERE m.id_socio = a.id_socio
              ORDER BY m.fecha_inicio DESC LIMIT 1) AS plan_socio
      FROM asistencia a
      JOIN socios s ON s.id_socio = a.id_socio
      WHERE (a.fecha_hora_ingreso AT TIME ZONE 'America/Lima')::date
            = (NOW() AT TIME ZONE 'America/Lima')::date
      ORDER BY a.fecha_hora_ingreso DESC
    `);
    return res.json(result.rows);
  } catch (err) {
    console.error('Error getIngresosHoy:', err.message);
    return res.status(500).json({ error: 'Error al obtener los ingresos de hoy.' });
  }
}

// POST /api/asistencia — registrar el ingreso de un socio
// Body: { id_socio }
export async function registrarIngreso(req, res) {
  const { id_socio } = req.body;
  if (!id_socio) {
    return res.status(400).json({ error: 'Falta el socio.' });
  }

  try {
    // 0. Verificar que el socio esté activo (no dado de baja)
    const socioRes = await query('SELECT estado FROM socios WHERE id_socio = $1', [id_socio]);
    if (socioRes.rows.length === 0) {
      return res.status(404).json({ error: 'Socio no encontrado.' });
    }
    if (socioRes.rows[0].estado !== 'activo') {
      return res.status(409).json({ error: 'El socio está inactivo (dado de baja). No puede registrar ingreso.' });
    }

    // 1. Verificar que el socio tenga una membresía vigente
    const memRes = await query(`
      SELECT estado, fecha_vencimiento
      FROM membresias
      WHERE id_socio = $1
      ORDER BY fecha_inicio DESC LIMIT 1
    `, [id_socio]);

    if (memRes.rows.length === 0) {
      return res.status(409).json({ error: 'El socio no tiene una membresía asignada.' });
    }
    const mem = memRes.rows[0];
    const vencida = new Date(mem.fecha_vencimiento) < new Date(new Date().toDateString());
    if (mem.estado === 'suspendida' || vencida) {
      return res.status(409).json({ error: 'La membresía del socio está vencida o suspendida.' });
    }

    // 2. Verificar que no haya ingresado ya hoy (día de Perú)
    const hoyRes = await query(`
      SELECT 1 FROM asistencia
      WHERE id_socio = $1
        AND (fecha_hora_ingreso AT TIME ZONE 'America/Lima')::date
            = (NOW() AT TIME ZONE 'America/Lima')::date
    `, [id_socio]);
    if (hoyRes.rows.length > 0) {
      return res.status(409).json({ error: 'El socio ya registró su ingreso hoy.' });
    }

    // 3. Registrar el ingreso
    const insRes = await query(`
      INSERT INTO asistencia (id_socio, registrado_por)
      VALUES ($1, $2)
      RETURNING id_asistencia, id_socio, fecha_hora_ingreso
    `, [id_socio, req.usuario.id_usuario]);

    const ingreso = insRes.rows[0];

    // 4. Devolver con nombre del socio y plan
    const fullRes = await query(`
      SELECT a.id_asistencia, a.id_socio,
             s.nombres || ' ' || s.apellidos AS nombre_socio,
             a.fecha_hora_ingreso,
             (SELECT p.nombre FROM membresias m
              JOIN planes p ON p.id_plan = m.id_plan
              WHERE m.id_socio = a.id_socio
              ORDER BY m.fecha_inicio DESC LIMIT 1) AS plan_socio
      FROM asistencia a
      JOIN socios s ON s.id_socio = a.id_socio
      WHERE a.id_asistencia = $1
    `, [ingreso.id_asistencia]);

    return res.status(201).json(fullRes.rows[0]);
  } catch (err) {
    console.error('Error registrarIngreso:', err.message);
    return res.status(500).json({ error: 'Error al registrar el ingreso.' });
  }
}
