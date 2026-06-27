/// Datos completos de la cuenta del usuario autenticado (GET /auth/me).
class CuentaInfo {
  final String    nombre;
  final String    correo;
  final String    rol;
  final bool      activo;
  final DateTime? fechaCreacion;

  const CuentaInfo({
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.activo,
    this.fechaCreacion,
  });

  String get rolLabel {
    switch (rol) {
      case 'administrador': return 'Administrador';
      case 'socio':         return 'Socio';
      default:              return 'Recepcionista';
    }
  }

  factory CuentaInfo.fromJson(Map<String, dynamic> j) {
    return CuentaInfo(
      nombre:        (j['nombre'] as String?) ?? '—',
      correo:        (j['correo'] as String?) ?? '—',
      rol:           (j['rol']    as String?) ?? 'recepcionista',
      activo:        (j['activo'] as bool?)   ?? true,
      fechaCreacion: _parseFecha(j['fecha_creacion']),
    );
  }

  // El backend devuelve la fecha en UTC; restamos 5h (Perú es UTC-5).
  static DateTime? _parseFecha(dynamic v) {
    if (v == null) return null;
    try {
      final clean = v.toString()
          .replaceFirst(' ', 'T')
          .replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), '')
          .replaceAll('Z', '');
      final utc = DateTime.utc(
        int.parse(clean.substring(0, 4)),
        int.parse(clean.substring(5, 7)),
        int.parse(clean.substring(8, 10)),
        clean.length >= 13 ? int.parse(clean.substring(11, 13)) : 0,
        clean.length >= 16 ? int.parse(clean.substring(14, 16)) : 0,
      );
      return utc.subtract(const Duration(hours: 5));
    } catch (_) {
      return null;
    }
  }
}
