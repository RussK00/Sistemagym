class Membresia {
  final int      id;
  final int      idSocio;
  final String   nombreSocio;
  final int      idPlan;
  final String   nombrePlan;
  final DateTime fechaInicio;
  final DateTime fechaVencimiento;
  final String   estado;       // 'activa' | 'vencida' | 'suspendida'
  final double   montoPagado;
  final String   metodoPago;   // 'efectivo' | 'transferencia'
  final String   observaciones;

  const Membresia({
    required this.id,
    required this.idSocio,
    required this.nombreSocio,
    required this.idPlan,
    required this.nombrePlan,
    required this.fechaInicio,
    required this.fechaVencimiento,
    required this.estado,
    required this.montoPagado,
    required this.metodoPago,
    this.observaciones = '',
  });

  factory Membresia.fromJson(Map<String, dynamic> j) {
    return Membresia(
      id:               j['id_membresia'] as int,
      idSocio:          j['id_socio'] as int,
      nombreSocio:      j['nombre_socio'] as String,
      idPlan:           j['id_plan'] as int,
      nombrePlan:       j['nombre_plan'] as String,
      fechaInicio:      DateTime.parse(j['fecha_inicio'] as String),
      fechaVencimiento: DateTime.parse(j['fecha_vencimiento'] as String),
      estado:           j['estado'] as String,
      montoPagado:      j['monto_pagado'] == null ? 0 : double.parse(j['monto_pagado'].toString()),
      metodoPago:       (j['metodo_pago'] as String?) ?? 'efectivo',
    );
  }

  int get diasRestantes {
    final diff = fechaVencimiento.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get estadoEfectivo {
    if (estado == 'suspendida') return 'suspendida';
    if (DateTime.now().isAfter(fechaVencimiento)) return 'vencida';
    return 'activa';
  }
}
