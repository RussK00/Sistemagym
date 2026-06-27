import 'package:stanleygym_app/features/ventas/models/venta.dart';

// Registro de compras de suplementos mock. En producción: GET /ventas
final mockVentas = <Venta>[
  Venta(id: 1, idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  idProducto: 1, nombreProducto: 'Proteína Whey 2kg',           cantidad: 1, precioUnitario: 180, fechaVenta: DateTime(2026, 6, 2)),
  Venta(id: 2, idSocio: 2, nombreSocio: 'María Torres Lomas', idProducto: 2, nombreProducto: 'Creatina Monohidratada 300g', cantidad: 1, precioUnitario: 90,  fechaVenta: DateTime(2026, 6, 5)),
  Venta(id: 3, idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  idProducto: 4, nombreProducto: 'Pre-entreno 30 dosis',         cantidad: 2, precioUnitario: 120, fechaVenta: DateTime(2026, 5, 28)),
];
