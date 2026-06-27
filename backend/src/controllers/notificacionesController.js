import { query } from '../config/db.js';
import { enviarPushASocio } from '../services/pushService.js';

// Lógica central: detecta membresías por vencer y crea notificaciones.
// Reutilizable por el endpoint manual y por el cron job diario.
// Devuelve cuántas notificaciones nuevas se crearon.
export async function generarNotificacionesVencimiento() {
  // 1. Leer la configuración (días de anticipación + si está activo)
  const cfg = await query('SELECT dias_anticipacion, notificaciones_activas FROM configuracion WHERE id = 1');
  const dias       = cfg.rows[0]?.dias_anticipacion ?? 3;
  const activas    = cfg.rows[0]?.notificaciones_activas ?? true;
  if (!activas) return 0;

  // 2. Membresía vigente (la más reciente) de cada socio que vence dentro del rango
  const porVencer = await query(`
    SELECT ult.id_socio, ult.id_membresia, ult.fecha_vencimiento, p.nombre AS nombre_plan,
           (ult.fecha_vencimiento - CURRENT_DATE) AS dias_restantes
    FROM (
      SELECT DISTINCT ON (id_socio) id_socio, id_membresia, id_plan, fecha_vencimiento, estado
      FROM membresias ORDER BY id_socio, fecha_inicio DESC
    ) ult
    JOIN planes p ON p.id_plan = ult.id_plan
    WHERE ult.estado = 'activa'
      AND ult.fecha_vencimiento >= CURRENT_DATE
      AND ult.fecha_vencimiento <= CURRENT_DATE + $1::int
  `, [dias]);

  let creadas = 0;
  for (const m of porVencer.rows) {
    // 3. Evitar duplicados: ¿ya hay una notificación para esta membresía sin leer?
    const existe = await query(`
      SELECT 1 FROM notificaciones
      WHERE id_membresia = $1 AND tipo = 'vencimiento' AND leida = FALSE
    `, [m.id_membresia]);
    if (existe.rows.length > 0) continue;

    const d = Number(m.dias_restantes);
    const cuando = d === 0 ? 'hoy' : d === 1 ? 'mañana' : `en ${d} días`;
    const titulo = 'Tu membresía está por vencer';
    const mensaje = `Tu plan ${m.nombre_plan} vence ${cuando}. `
      + 'Acércate a recepción para renovarla y no perder el acceso.';

    await query(`
      INSERT INTO notificaciones (id_socio, id_membresia, titulo, mensaje, tipo)
      VALUES ($1, $2, $3, $4, 'vencimiento')
    `, [m.id_socio, m.id_membresia, titulo, mensaje]);

    // Enviar también el push real al celular del socio (Capa 2).
    await enviarPushASocio(m.id_socio, titulo, mensaje);

    creadas++;
  }
  return creadas;
}

// POST /api/notificaciones/generar — dispara la generación manualmente (para pruebas)
export async function generarManual(req, res) {
  try {
    const creadas = await generarNotificacionesVencimiento();
    return res.json({ mensaje: `Se generaron ${creadas} notificación(es) nueva(s).`, creadas });
  } catch (err) {
    console.error('Error generarManual:', err.message);
    return res.status(500).json({ error: 'Error al generar notificaciones.' });
  }
}

// GET /api/socio/mis-notificaciones — notificaciones del socio autenticado
export async function getMisNotificaciones(req, res) {
  const idSocio = req.usuario.id_socio;
  if (!idSocio) return res.status(403).json({ error: 'Esta cuenta no está vinculada a un socio.' });

  try {
    const result = await query(`
      SELECT id_notificacion, id_socio, titulo, mensaje, tipo, leida, fecha_creacion
      FROM notificaciones
      WHERE id_socio = $1
      ORDER BY fecha_creacion DESC
    `, [idSocio]);
    return res.json(result.rows);
  } catch (err) {
    console.error('Error getMisNotificaciones:', err.message);
    return res.status(500).json({ error: 'Error al obtener tus notificaciones.' });
  }
}

// PATCH /api/socio/notificaciones/:id/leida — marcar una como leída
export async function marcarLeida(req, res) {
  const idSocio = req.usuario.id_socio;
  const { id } = req.params;
  try {
    const result = await query(`
      UPDATE notificaciones SET leida = TRUE
      WHERE id_notificacion = $1 AND id_socio = $2
      RETURNING id_notificacion
    `, [id, idSocio]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Notificación no encontrada.' });
    }
    return res.json({ mensaje: 'Notificación marcada como leída.' });
  } catch (err) {
    console.error('Error marcarLeida:', err.message);
    return res.status(500).json({ error: 'Error al actualizar la notificación.' });
  }
}
