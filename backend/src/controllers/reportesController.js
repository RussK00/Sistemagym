import { query } from '../config/db.js';

// GET /api/reportes/dashboard — métricas y datos para el panel del admin
export async function getDashboard(req, res) {
  try {
    // ── Tarjetas ──────────────────────────────────────────────────────────
    const sociosActivos = await query(
      `SELECT COUNT(*)::int AS n FROM socios WHERE estado = 'activo'`);

    const sociosNuevosMes = await query(`
      SELECT COUNT(*)::int AS n FROM socios
      WHERE EXTRACT(MONTH FROM fecha_registro) = EXTRACT(MONTH FROM CURRENT_DATE)
        AND EXTRACT(YEAR  FROM fecha_registro) = EXTRACT(YEAR  FROM CURRENT_DATE)`);

    const ingresosHoy = await query(
      `SELECT COUNT(*)::int AS n FROM asistencia
       WHERE (fecha_hora_ingreso AT TIME ZONE 'America/Lima')::date
             = (NOW() AT TIME ZONE 'America/Lima')::date`);

    const dias = (await query('SELECT dias_anticipacion FROM configuracion WHERE id = 1'))
      .rows[0]?.dias_anticipacion ?? 3;

    const porVencer = await query(`
      SELECT COUNT(*)::int AS n FROM (
        SELECT DISTINCT ON (id_socio) id_socio, fecha_vencimiento, estado
        FROM membresias ORDER BY id_socio, fecha_inicio DESC
      ) ult
      WHERE estado = 'activa'
        AND fecha_vencimiento >= CURRENT_DATE
        AND fecha_vencimiento <= CURRENT_DATE + $1::int
    `, [dias]);

    const ingresosMes = await query(`
      SELECT COALESCE(SUM(monto), 0)::numeric AS total FROM pagos
      WHERE date_trunc('month', fecha_pago) = date_trunc('month', CURRENT_DATE)`);

    const ingresosMesAnt = await query(`
      SELECT COALESCE(SUM(monto), 0)::numeric AS total FROM pagos
      WHERE date_trunc('month', fecha_pago) = date_trunc('month', CURRENT_DATE - INTERVAL '1 month')`);

    const ventasMes = await query(`
      SELECT COALESCE(SUM(cantidad), 0)::int AS n FROM ventas
      WHERE date_trunc('month', fecha_venta) = date_trunc('month', CURRENT_DATE)`);

    const ventasMesAnt = await query(`
      SELECT COALESCE(SUM(cantidad), 0)::int AS n FROM ventas
      WHERE date_trunc('month', fecha_venta) = date_trunc('month', CURRENT_DATE - INTERVAL '1 month')`);

    // ── Gráfico: asistencia por mes (año actual) ──────────────────────────
    const asistRows = await query(`
      SELECT EXTRACT(MONTH FROM fecha_hora_ingreso)::int AS mes, COUNT(*)::int AS n
      FROM asistencia
      WHERE EXTRACT(YEAR FROM fecha_hora_ingreso) = EXTRACT(YEAR FROM CURRENT_DATE)
      GROUP BY mes`);
    const asistenciaPorMes = Array(12).fill(0);
    for (const r of asistRows.rows) asistenciaPorMes[r.mes - 1] = r.n;

    // ── Últimos socios registrados ────────────────────────────────────────
    const ultimos = await query(`
      SELECT s.id_socio,
             s.nombres || ' ' || s.apellidos AS nombre,
             s.estado, s.fecha_registro,
             (SELECT p.nombre FROM membresias m
              JOIN planes p ON p.id_plan = m.id_plan
              WHERE m.id_socio = s.id_socio ORDER BY m.fecha_inicio DESC LIMIT 1) AS plan
      FROM socios s
      ORDER BY s.id_socio DESC LIMIT 5`);

    // ── Alertas: productos con stock bajo ─────────────────────────────────
    const stockBajo = await query(`
      SELECT nombre, stock FROM productos
      WHERE activo = TRUE AND stock <= 5
      ORDER BY stock ASC LIMIT 5`);

    return res.json({
      socios_activos:        sociosActivos.rows[0].n,
      socios_nuevos_mes:     sociosNuevosMes.rows[0].n,
      ingresos_hoy:          ingresosHoy.rows[0].n,
      ingresos_mes:          Number(ingresosMes.rows[0].total),
      ingresos_mes_anterior: Number(ingresosMesAnt.rows[0].total),
      ventas_unidades_mes:   ventasMes.rows[0].n,
      ventas_unidades_mes_anterior: ventasMesAnt.rows[0].n,
      membresias_por_vencer: porVencer.rows[0].n,
      dias_anticipacion:     dias,
      asistencia_por_mes:    asistenciaPorMes,
      ultimos_socios:        ultimos.rows,
      stock_bajo:            stockBajo.rows,
    });
  } catch (err) {
    console.error('Error getDashboard:', err.message);
    return res.status(500).json({ error: 'Error al generar el panel.' });
  }
}

// GET /api/reportes/asistencia?mes=6&anio=2026
// Asistencia de un mes: lista de ingresos con socio y plan.
export async function getAsistenciaMensual(req, res) {
  const mes  = Number(req.query.mes)  || (new Date().getMonth() + 1);
  const anio = Number(req.query.anio) || new Date().getFullYear();

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
      WHERE EXTRACT(MONTH FROM a.fecha_hora_ingreso) = $1
        AND EXTRACT(YEAR  FROM a.fecha_hora_ingreso) = $2
      ORDER BY a.fecha_hora_ingreso DESC
    `, [mes, anio]);

    return res.json(result.rows);
  } catch (err) {
    console.error('Error getAsistenciaMensual:', err.message);
    return res.status(500).json({ error: 'Error al generar el reporte de asistencia.' });
  }
}

// GET /api/reportes/membresias
// Estado de la membresía vigente de cada socio.
export async function getEstadoMembresias(req, res) {
  try {
    const result = await query(`
      SELECT DISTINCT ON (m.id_socio)
             m.id_membresia, m.id_socio,
             s.nombres || ' ' || s.apellidos AS nombre_socio,
             m.id_plan, p.nombre AS nombre_plan,
             m.fecha_inicio, m.fecha_vencimiento, m.estado,
             NULL::numeric AS monto_pagado, NULL AS metodo_pago
      FROM membresias m
      JOIN socios s ON s.id_socio = m.id_socio
      JOIN planes p ON p.id_plan = m.id_plan
      ORDER BY m.id_socio, m.fecha_inicio DESC, m.id_membresia DESC
    `);
    return res.json(result.rows);
  } catch (err) {
    console.error('Error getEstadoMembresias:', err.message);
    return res.status(500).json({ error: 'Error al generar el reporte de membresías.' });
  }
}
