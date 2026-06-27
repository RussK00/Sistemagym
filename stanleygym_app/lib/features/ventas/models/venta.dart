class Venta {
  final int      id;
  final int      idSocio;
  final String   nombreSocio;
  final int      idProducto;
  final String   nombreProducto;
  final int      cantidad;
  final double   precioUnitario;
  final DateTime fechaVenta;

  const Venta({
    required this.id,
    required this.idSocio,
    required this.nombreSocio,
    required this.idProducto,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.fechaVenta,
  });

  double get total => cantidad * precioUnitario;

  factory Venta.fromJson(Map<String, dynamic> j) {
    return Venta(
      id:             j['id_venta'] as int,
      idSocio:        j['id_socio'] as int,
      nombreSocio:    (j['nombre_socio'] as String?) ?? '',
      idProducto:     j['id_producto'] as int,
      nombreProducto: j['nombre_producto'] as String,
      cantidad:       j['cantidad'] as int,
      precioUnitario: double.parse(j['precio_unitario'].toString()),
      fechaVenta:     DateTime.parse(j['fecha_venta'] as String),
    );
  }
}
