import { query } from '../config/db.js';

// Helper: el id del socio autenticado (del token)
function idSocioDe(req) {
  return req.usuario.id_socio;
}

// GET /api/socio/mi-membresia — membresía vigente del socio autenticado
export async function getMiMembresia(req, res) {
  const idSocio = idSocioDe(req);
  if (!idSocio) return res.status(403).json({ error: 'Esta cuenta no está vinculada a un socio.' });

  try {
    const result = await query(`
      SELECT m.id_membresia, m.id_socio,
             s.nombres || ' ' || s.apellidos AS nombre_socio,
             m.id_plan, p.nombre AS nombre_plan,
             m.fecha_inicio, m.fecha_vencimiento, m.estado,
             pg.monto       AS monto_pagado,
             pg.metodo_pago AS metodo_pago
      FROM membresias m
      JOIN socios s ON s.id_socio = m.id_socio
      JOIN planes p ON p.id_plan = m.id_plan
      LEFT JOIN LATERAL (
        SELECT monto, metodo_pago FROM pagos
        WHERE id_membresia = m.id_membresia ORDER BY id_pago DESC LIMIT 1
      ) pg ON TRUE
      WHERE m.id_socio = $1
      ORDER BY m.fecha_inicio DESC, m.id_membresia DESC
      LIMIT 1
    `, [idSocio]);

    // Sin membresía → 200 con null (el frontend muestra "sin membresía")
    return res.json(result.rows[0] ?? null);
  } catch (err) {
    console.error('Error getMiMembresia:', err.message);
    return res.status(500).json({ error: 'Error al obtener tu membresía.' });
  }
}

// POST /api/socio/token-fcm — registrar el token del dispositivo del socio
// Body: { token }
export async function registrarTokenFcm(req, res) {
  const idSocio = idSocioDe(req);
  const { token } = req.body;
  if (!idSocio) return res.status(403).json({ error: 'Esta cuenta no está vinculada a un socio.' });
  if (!token)   return res.status(400).json({ error: 'Token no proporcionado.' });

  try {
    // Upsert: si el token ya existe, se reasigna al socio actual; si no, se inserta.
    await query(`
      INSERT INTO tokens_fcm (id_socio, token)
      VALUES ($1, $2)
      ON CONFLICT (token) DO UPDATE SET id_socio = $1, fecha_registro = NOW()
    `, [idSocio, token]);
    return res.json({ mensaje: 'Token registrado.' });
  } catch (err) {
    console.error('Error registrarTokenFcm:', err.message);
    return res.status(500).json({ error: 'Error al registrar el token.' });
  }
}

// GET /api/socio/mi-asistencia — historial de asistencia del socio autenticado
export async function getMiAsistencia(req, res) {
  const idSocio = idSocioDe(req);
  if (!idSocio) return res.status(403).json({ error: 'Esta cuenta no está vinculada a un socio.' });

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
      WHERE a.id_socio = $1
      ORDER BY a.fecha_hora_ingreso DESC
    `, [idSocio]);

    return res.json(result.rows);
  } catch (err) {
    console.error('Error getMiAsistencia:', err.message);
    return res.status(500).json({ error: 'Error al obtener tu asistencia.' });
  }
}
