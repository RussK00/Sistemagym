import 'package:stanleygym_app/features/membresias/models/membresia.dart';

final mockMembresias = <Membresia>[
  Membresia(
    id: 1, idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',
    idPlan: 1, nombrePlan: 'Mensual',
    fechaInicio:      DateTime.now().subtract(const Duration(days: 20)),
    fechaVencimiento: DateTime.now().add(const Duration(days: 10)),
    estado: 'activa', montoPagado: 80, metodoPago: 'efectivo',
  ),
  Membresia(
    id: 2, idSocio: 2, nombreSocio: 'María Torres Lomas',
    idPlan: 2, nombrePlan: 'Trimestral',
    fechaInicio:      DateTime.now().subtract(const Duration(days: 85)),
    fechaVencimiento: DateTime.now().add(const Duration(days: 5)),
    estado: 'activa', montoPagado: 200, metodoPago: 'transferencia',
  ),
  Membresia(
    id: 3, idSocio: 3, nombreSocio: 'Jhon Sánchez Ruiz',
    idPlan: 1, nombrePlan: 'Mensual',
    fechaInicio:      DateTime.now().subtract(const Duration(days: 45)),
    fechaVencimiento: DateTime.now().subtract(const Duration(days: 15)),
    estado: 'activa', montoPagado: 80, metodoPago: 'efectivo',
  ),
];
