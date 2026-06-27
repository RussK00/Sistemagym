import { pool, query } from '../config/db.js';

// Consulta base: muestra la membresía MÁS RECIENTE por socio,
// con nombre del socio, nombre del plan y datos del último pago.
const SELECT_MEMBRESIAS = `
  SELECT DISTINCT ON (m.id_socio)
         m.id_membresia, m.id_socio,
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
    WHERE id_membresia = m.id_membresia
    ORDER BY id_pago DESC LIMIT 1
  ) pg ON TRUE
  ORDER BY m.id_socio, m.fecha_inicio DESC, m.id_membresia DESC
`;

// GET /api/membresias
export async function getMembresias(req, res) {
  try {
    const result = await query(SELECT_MEMBRESIAS);
    return res.json(result.rows);
  } catch (err) {
    console.error('Error getMembresias:', err.message);
    return res.status(500).json({ error: 'Error al obtener las membresías.' });
  }
}

// POST /api/membresias
// Body: { id_socio, id_plan, fecha_inicio, metodo_pago }
// Crea la membresía + su pago en una transacción.
export async function createMembresia(req, res) {
  const { id_socio, id_plan, fecha_inicio, metodo_pago } = req.body;

  if (!id_socio || !id_plan || !fecha_inicio || !metodo_pago) {
    return res.status(400).json({ error: 'Faltan datos obligatorios (socio, plan, fecha, método de pago).' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Obtener el plan (precio y duración)
    const planRes = await client.query(
      'SELECT nombre, duracion_dias, precio FROM planes WHERE id_plan = $1', [id_plan]);
    if (planRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Plan no encontrado.' });
    }
    const plan = planRes.rows[0];

    // 2. Calcular fecha de vencimiento
    const vencRes = await client.query(
      `SELECT ($1::date + ($2 || ' days')::interval)::date AS venc`, [fecha_inicio, plan.duracion_dias]);
    const fecha_vencimiento = vencRes.rows[0].venc;

    // 3. Insertar la membresía
    const memRes = await client.query(
      `INSERT INTO membresias (id_socio, id_plan, fecha_inicio, fecha_vencimiento, estado)
       VALUES ($1, $2, $3, $4, 'activa')
       RETURNING id_membresia`,
      [id_socio, id_plan, fecha_inicio, fecha_vencimiento]
    );
    const idMembresia = memRes.rows[0].id_membresia;

    // 4. Registrar el pago asociado
    await client.query(
      `INSERT INTO pagos (id_membresia, id_socio, concepto, monto, fecha_pago, metodo_pago, registrado_por)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [idMembresia, id_socio, `Membresía ${plan.nombre}`, plan.precio, fecha_inicio, metodo_pago, req.usuario.id_usuario]
    );

    await client.query('COMMIT');

    // 5. Devolver la membresía recién creada (con nombres y pago)
    const result = await query(
      `SELECT m.id_membresia, m.id_socio,
              s.nombres || ' ' || s.apellidos AS nombre_socio,
              m.id_plan, p.nombre AS nombre_plan,
              m.fecha_inicio, m.fecha_vencimiento, m.estado,
              $2::numeric AS monto_pagado, $3 AS metodo_pago
       FROM membresias m
       JOIN socios s ON s.id_socio = m.id_socio
       JOIN planes p ON p.id_plan = m.id_plan
       WHERE m.id_membresia = $1`,
      [idMembresia, plan.precio, metodo_pago]
    );
    return res.status(201).json(result.rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error createMembresia:', err.message);
    return res.status(500).json({ error: 'Error al crear la membresía.' });
  } finally {
    client.release();
  }
}
