class CuentaPersonal {
  final int      id;
  final String   nombre;
  final String   correo;
  final bool     activo;
  final DateTime fechaCreacion;

  const CuentaPersonal({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.activo,
    required this.fechaCreacion,
  });

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();

  factory CuentaPersonal.fromJson(Map<String, dynamic> j) {
    return CuentaPersonal(
      id:            j['id_usuario'] as int,
      nombre:        (j['nombre'] as String?) ?? '',
      correo:        (j['correo'] as String?) ?? '',
      activo:        (j['activo'] as bool?) ?? true,
      fechaCreacion: _parseFecha(j['fecha_creacion']) ?? DateTime.now(),
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

  CuentaPersonal copyWith({String? nombre, String? correo, bool? activo}) {
    return CuentaPersonal(
      id:            id,
      nombre:        nombre ?? this.nombre,
      correo:        correo ?? this.correo,
      activo:        activo ?? this.activo,
      fechaCreacion: fechaCreacion,
    );
  }
}
