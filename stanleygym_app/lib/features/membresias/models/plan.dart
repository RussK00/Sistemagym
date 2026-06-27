class Plan {
  final int          id;
  final String       nombre;
  final int          duracionDias;
  final double       precio;
  final String       descripcion;
  final bool         activo;
  final List<String> caracteristicas;
  final int          sociosActivos;

  const Plan({
    required this.id,
    required this.nombre,
    required this.duracionDias,
    required this.precio,
    required this.descripcion,
    this.activo = true,
    this.caracteristicas = const [],
    this.sociosActivos = 0,
  });

  factory Plan.fromJson(Map<String, dynamic> j) {
    return Plan(
      id:           j['id_plan'] as int,
      nombre:       j['nombre'] as String,
      duracionDias: j['duracion_dias'] as int,
      precio:       double.parse(j['precio'].toString()),
      descripcion:  (j['descripcion'] as String?) ?? '',
      activo:       (j['activo'] as bool?) ?? true,
      caracteristicas: ((j['caracteristicas'] as List?) ?? [])
          .map((e) => e.toString()).toList(),
      sociosActivos: (j['socios_activos'] as int?) ?? 0,
    );
  }
}
