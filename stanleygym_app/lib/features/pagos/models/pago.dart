class Pago {
  final int      id;
  final int      idSocio;
  final String   nombreSocio;
  final String   concepto;     // Ej: "Membresía Mensual", "Renovación Trimestral"
  final double   monto;
  final DateTime fechaPago;
  final String   metodoPago;   // 'efectivo' | 'transferencia'
  final String   observaciones;

  const Pago({
    required this.id,
    required this.idSocio,
    required this.nombreSocio,
    required this.concepto,
    required this.monto,
    required this.fechaPago,
    required this.metodoPago,
    this.observaciones = '',
  });

  factory Pago.fromJson(Map<String, dynamic> j) {
    return Pago(
      id:            j['id_pago'] as int,
      idSocio:       j['id_socio'] as int,
      nombreSocio:   (j['nombre_socio'] as String?) ?? '',
      concepto:      j['concepto'] as String,
      monto:         double.parse(j['monto'].toString()),
      fechaPago:     DateTime.parse(j['fecha_pago'] as String),
      metodoPago:    j['metodo_pago'] as String,
      observaciones: (j['observaciones'] as String?) ?? '',
    );
  }
}
