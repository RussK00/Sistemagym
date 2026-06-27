import { query } from '../config/db.js';

// GET /api/pagos — historial de pagos con nombre del socio
export async function getPagos(req, res) {
  try {
    const result = await query(`
      SELECT pg.id_pago, pg.id_socio,
             s.nombres || ' ' || s.apellidos AS nombre_socio,
             pg.concepto, pg.monto, pg.fecha_pago, pg.metodo_pago, pg.observaciones
      FROM pagos pg
      JOIN socios s ON s.id_socio = pg.id_socio
      ORDER BY pg.fecha_pago DESC, pg.id_pago DESC
    `);
    return res.json(result.rows);
  } catch (err) {
    console.error('Error getPagos:', err.message);
    return res.status(500).json({ error: 'Error al obtener los pagos.' });
  }
}

// POST /api/pagos — registrar un pago manual
// Body: { id_socio, concepto, monto, fecha_pago, metodo_pago }
export async function createPago(req, res) {
  const { id_socio, concepto, monto, fecha_pago, metodo_pago } = req.body;

  if (!id_socio || !concepto || monto == null || !metodo_pago) {
    return res.status(400).json({ error: 'Faltan datos obligatorios (socio, concepto, monto, método).' });
  }

  try {
    const result = await query(`
      INSERT INTO pagos (id_socio, concepto, monto, fecha_pago, metodo_pago, registrado_por)
      VALUES ($1, $2, $3, COALESCE($4, CURRENT_DATE), $5, $6)
      RETURNING id_pago, id_socio, concepto, monto, fecha_pago, metodo_pago, observaciones
    `, [id_socio, concepto.trim(), monto, fecha_pago, metodo_pago, req.usuario.id_usuario]);

    // Agregar el nombre del socio a la respuesta
    const socioRes = await query(
      `SELECT nombres || ' ' || apellidos AS nombre_socio FROM socios WHERE id_socio = $1`, [id_socio]);

    const pago = result.rows[0];
    pago.nombre_socio = socioRes.rows[0]?.nombre_socio ?? '';

    return res.status(201).json(pago);
  } catch (err) {
    console.error('Error createPago:', err.message);
    return res.status(500).json({ error: 'Error al registrar el pago.' });
  }
}
