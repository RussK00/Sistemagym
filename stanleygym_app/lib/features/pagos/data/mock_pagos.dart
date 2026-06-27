import 'package:stanleygym_app/features/pagos/models/pago.dart';

// Historial de pagos mock. En producción: GET /pagos
final mockPagos = <Pago>[
  Pago(id: 1, idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  concepto: 'Membresía Mensual',     monto: 80,  fechaPago: DateTime(2026, 5, 18), metodoPago: 'efectivo'),
  Pago(id: 2, idSocio: 2, nombreSocio: 'María Torres Lomas', concepto: 'Membresía Trimestral',  monto: 200, fechaPago: DateTime(2026, 3, 14), metodoPago: 'transferencia'),
  Pago(id: 3, idSocio: 3, nombreSocio: 'Jhon Sánchez Ruiz',  concepto: 'Membresía Mensual',     monto: 80,  fechaPago: DateTime(2026, 4, 22), metodoPago: 'efectivo'),
  Pago(id: 4, idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  concepto: 'Renovación Mensual',    monto: 80,  fechaPago: DateTime(2026, 4, 18), metodoPago: 'efectivo'),
];
