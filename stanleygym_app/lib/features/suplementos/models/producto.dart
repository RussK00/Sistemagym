class Producto {
  final int    id;
  final String nombre;
  final String descripcion;
  final String categoria; // Suplemento | Bebida | Accesorio | Otro
  final double precio;
  final int    stock;
  final bool   activo;
  final String imagenUrl; // foto del producto (vacío si no tiene)

  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.categoria = 'Suplemento',
    required this.precio,
    required this.stock,
    this.activo = true,
    this.imagenUrl = '',
  });

  /// Categorías válidas de producto del gimnasio (el agua va dentro de Bebida).
  static const categorias = ['Suplemento', 'Bebida', 'Accesorio', 'Otro'];

  factory Producto.fromJson(Map<String, dynamic> j) {
    return Producto(
      id:          j['id_producto'] as int,
      nombre:      j['nombre'] as String,
      descripcion: (j['descripcion'] as String?) ?? '',
      categoria:   (j['categoria'] as String?) ?? 'Suplemento',
      precio:      double.parse(j['precio'].toString()),
      stock:       j['stock'] as int,
      activo:      j['activo'] as bool,
      imagenUrl:   (j['imagen_url'] as String?) ?? '',
    );
  }

  Producto copyWith({
    String? nombre,
    String? descripcion,
    String? categoria,
    double? precio,
    int?    stock,
    bool?   activo,
    String? imagenUrl,
  }) {
    return Producto(
      id:          id,
      nombre:      nombre      ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria:   categoria   ?? this.categoria,
      precio:      precio      ?? this.precio,
      stock:       stock       ?? this.stock,
      activo:      activo      ?? this.activo,
      imagenUrl:   imagenUrl   ?? this.imagenUrl,
    );
  }
}
