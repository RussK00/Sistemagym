class Socio {
  final int      id;
  final String   nombres;
  final String   apellidos;
  final String   dni;
  final String   telefono;
  final String   correo;
  final String   estado; // 'activo' | 'inactivo'
  final DateTime fechaRegistro;

  const Socio({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.dni,
    required this.telefono,
    required this.correo,
    required this.estado,
    required this.fechaRegistro,
  });

  String get nombreCompleto => '$nombres $apellidos';

  factory Socio.fromJson(Map<String, dynamic> j) {
    return Socio(
      id:            j['id_socio'] as int,
      nombres:       j['nombres']   as String,
      apellidos:     j['apellidos'] as String,
      dni:           j['dni']       as String,
      telefono:      (j['telefono'] as String?) ?? '',
      correo:        (j['correo']   as String?) ?? '',
      estado:        j['estado']    as String,
      fechaRegistro: DateTime.parse(j['fecha_registro'] as String),
    );
  }

  Socio copyWith({
    String? nombres,
    String? apellidos,
    String? dni,
    String? telefono,
    String? correo,
    String? estado,
  }) {
    return Socio(
      id:            id,
      nombres:       nombres       ?? this.nombres,
      apellidos:     apellidos     ?? this.apellidos,
      dni:           dni           ?? this.dni,
      telefono:      telefono      ?? this.telefono,
      correo:        correo        ?? this.correo,
      estado:        estado        ?? this.estado,
      fechaRegistro: fechaRegistro,
    );
  }
}
