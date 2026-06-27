class Asistencia {
  final int      id;
  final int      idSocio;
  final String   nombreSocio;
  final String   planSocio;
  final DateTime fechaHoraIngreso;

  const Asistencia({
    required this.id,
    required this.idSocio,
    required this.nombreSocio,
    required this.planSocio,
    required this.fechaHoraIngreso,
  });

  // Perú es UTC-5 todo el año (no usa horario de verano).
  static const _peruOffset = Duration(hours: 5);

  // La DB (Supabase) almacena UTC sin indicador de zona, p.ej.
  // "2026-06-19T20:08:03.04151". Restamos 5h fijas en vez de depender de
  // la zona del navegador (que en web puede reportarse como UTC).
  static DateTime _parseUtc(String s) {
    final clean = s
        .replaceFirst(' ', 'T')
        .replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), '') // quita +00:00 / -05:00
        .replaceAll('Z', '');                          // quita Z final
    final utc = DateTime.utc(
      int.parse(clean.substring(0, 4)),          // año
      int.parse(clean.substring(5, 7)),          // mes
      int.parse(clean.substring(8, 10)),         // día
      int.parse(clean.substring(11, 13)),        // hora
      int.parse(clean.substring(14, 16)),        // minuto
      int.parse(clean.substring(17, 19)),        // segundo
    );
    return utc.subtract(_peruOffset);
  }

  factory Asistencia.fromJson(Map<String, dynamic> j) {
    return Asistencia(
      id:               j['id_asistencia'] as int,
      idSocio:          j['id_socio'] as int,
      nombreSocio:      j['nombre_socio'] as String,
      planSocio:        (j['plan_socio'] as String?) ?? '—',
      fechaHoraIngreso: _parseUtc(j['fecha_hora_ingreso'] as String),
    );
  }
}
