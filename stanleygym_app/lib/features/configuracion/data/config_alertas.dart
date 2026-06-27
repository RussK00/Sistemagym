// Configuración global de alertas de vencimiento.
// En producción se guardaría en el backend (tabla de configuración del sistema).
class ConfigAlertas {
  ConfigAlertas._();

  // Días de anticipación con que se notifica al socio antes del vencimiento.
  // Valor por defecto según documentación: 3 días.
  static int diasAnticipacion = 3;

  // Si las notificaciones automáticas están activas.
  static bool notificacionesActivas = true;
}
