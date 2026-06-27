import { query } from '../config/db.js';

// Subconsulta: socios cuya membresía vigente (la más reciente) es de ese plan y está activa.
const SOCIOS_ACTIVOS = `
  COALESCE((
    SELECT COUNT(*) FROM (
      SELECT DISTINCT ON (id_socio) id_socio, id_plan, fecha_vencimiento, estado
      FROM membresias ORDER BY id_socio, fecha_inicio DESC
    ) ult
    WHERE ult.id_plan = p.id_plan
      AND ult.estado = 'activa'
      AND ult.fecha_vencimiento >= CURRENT_DATE
  ), 0)::int
`;

// GET /api/planes — lista de planes (con socios activos por plan).
// ?todos=true incluye inactivos (gestión del admin); sin param solo activos.
export async function getPlanes(req, res) {
  const todos = req.query.todos === 'true';
  try {
    const result = await query(
      `SELECT p.id_plan, p.nombre, p.duracion_dias, p.precio, p.descripcion,
              p.activo, p.caracteristicas, ${SOCIOS_ACTIVOS} AS socios_activos
       FROM planes p
       ${todos ? '' : 'WHERE p.activo = TRUE'}
       ORDER BY p.duracion_dias ASC`
    );
    return res.json(result.rows);
  } catch (err) {
    console.error('Error getPlanes:', err.message);
    return res.status(500).json({ error: 'Error al obtener los planes.' });
  }
}

// POST /api/planes — crear un plan (admin)
export async function createPlan(req, res) {
  const { nombre, duracion_dias, precio, descripcion, caracteristicas } = req.body;
  if (!nombre || duracion_dias == null || precio == null) {
    return res.status(400).json({ error: 'Nombre, duración y precio son obligatorios.' });
  }
  if (duracion_dias <= 0) {
    return res.status(400).json({ error: 'La duración debe ser mayor a 0 días.' });
  }
  try {
    const result = await query(
      `INSERT INTO planes (nombre, duracion_dias, precio, descripcion, caracteristicas, activo)
       VALUES ($1, $2, $3, $4, $5, TRUE)
       RETURNING id_plan, nombre, duracion_dias, precio, descripcion, activo, caracteristicas, 0::int AS socios_activos`,
      [nombre.trim(), duracion_dias, precio, descripcion?.trim() ?? '', JSON.stringify(caracteristicas ?? [])]
    );
    return res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error createPlan:', err.message);
    return res.status(500).json({ error: 'Error al crear el plan.' });
  }
}

// PUT /api/planes/:id — editar un plan (admin)
export async function updatePlan(req, res) {
  const { id } = req.params;
  const { nombre, duracion_dias, precio, descripcion, caracteristicas } = req.body;
  if (!nombre || duracion_dias == null || precio == null) {
    return res.status(400).json({ error: 'Nombre, duración y precio son obligatorios.' });
  }
  if (duracion_dias <= 0) {
    return res.status(400).json({ error: 'La duración debe ser mayor a 0 días.' });
  }
  try {
    const result = await query(
      `UPDATE planes
       SET nombre = $1, duracion_dias = $2, precio = $3, descripcion = $4, caracteristicas = $5
       WHERE id_plan = $6
       RETURNING id_plan, nombre, duracion_dias, precio, descripcion, activo, caracteristicas`,
      [nombre.trim(), duracion_dias, precio, descripcion?.trim() ?? '', JSON.stringify(caracteristicas ?? []), id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Plan no encontrado.' });
    }
    return res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updatePlan:', err.message);
    return res.status(500).json({ error: 'Error al actualizar el plan.' });
  }
}

// PATCH /api/planes/:id/estado — activar / desactivar (admin)
export async function togglePlan(req, res) {
  const { id } = req.params;
  try {
    const result = await query(
      `UPDATE planes SET activo = NOT activo
       WHERE id_plan = $1
       RETURNING id_plan, nombre, duracion_dias, precio, descripcion, activo, caracteristicas`,
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Plan no encontrado.' });
    }
    return res.json(result.rows[0]);
  } catch (err) {
    console.error('Error togglePlan:', err.message);
    return res.status(500).json({ error: 'Error al cambiar el estado del plan.' });
  }
}

// DELETE /api/planes/:id — eliminar (admin), solo si nadie lo usa
export async function deletePlan(req, res) {
  const { id } = req.params;
  try {
    // ¿Algún socio tiene su membresía vigente en este plan?
    const activos = await query(`
      SELECT COUNT(*) AS n FROM (
        SELECT DISTINCT ON (id_socio) id_socio, id_plan, fecha_vencimiento, estado
        FROM membresias ORDER BY id_socio, fecha_inicio DESC
      ) ult
      WHERE ult.id_plan = $1 AND ult.estado = 'activa' AND ult.fecha_vencimiento >= CURRENT_DATE
    `, [id]);

    if (Number(activos.rows[0].n) > 0) {
      return res.status(409).json({
        error: 'No puedes eliminar este plan porque tiene socios activos. Desactívalo en su lugar.',
      });
    }

    // ¿Tiene membresías históricas (no activas)? Si las tiene, tampoco se puede borrar
    // (rompería el historial); en ese caso también se sugiere desactivar.
    const historico = await query('SELECT 1 FROM membresias WHERE id_plan = $1 LIMIT 1', [id]);
    if (historico.rows.length > 0) {
      return res.status(409).json({
        error: 'No puedes eliminar este plan porque tiene membresías en el historial. Desactívalo en su lugar.',
      });
    }

    const result = await query('DELETE FROM planes WHERE id_plan = $1 RETURNING id_plan', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Plan no encontrado.' });
    }
    return res.json({ mensaje: 'Plan eliminado correctamente.' });
  } catch (err) {
    console.error('Error deletePlan:', err.message);
    return res.status(500).json({ error: 'Error al eliminar el plan.' });
  }
}
