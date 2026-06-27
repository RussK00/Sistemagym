class Notificacion {
  final int      id;
  final String   titulo;
  final String   mensaje;
  final String   tipo;
  final bool     leida;
  final DateTime fechaCreacion;

  const Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.fechaCreacion,
  });

  factory Notificacion.fromJson(Map<String, dynamic> j) {
    return Notificacion(
      id:            j['id_notificacion'] as int,
      titulo:        j['titulo'] as String,
      mensaje:       j['mensaje'] as String,
      tipo:          (j['tipo'] as String?) ?? 'vencimiento',
      leida:         j['leida'] as bool,
      fechaCreacion: DateTime.parse(j['fecha_creacion'] as String).toLocal(),
    );
  }
}
