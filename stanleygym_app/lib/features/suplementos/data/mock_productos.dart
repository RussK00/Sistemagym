import 'package:stanleygym_app/features/suplementos/models/producto.dart';

// Catálogo de suplementos mock. En producción: GET /productos
final mockProductos = <Producto>[
  Producto(id: 1, nombre: 'Proteína Whey 2kg',    descripcion: 'Proteína de suero, sabor chocolate', precio: 180, stock: 24, activo: true),
  Producto(id: 2, nombre: 'Creatina Monohidratada 300g', descripcion: 'Mejora fuerza y rendimiento',  precio: 90,  stock: 15, activo: true),
  Producto(id: 3, nombre: 'BCAA 250g',            descripcion: 'Aminoácidos de cadena ramificada',   precio: 75,  stock: 0,  activo: true),
  Producto(id: 4, nombre: 'Pre-entreno 30 dosis', descripcion: 'Energía y enfoque pre-entrenamiento', precio: 120, stock: 8,  activo: true),
  Producto(id: 5, nombre: 'Shaker 600ml',         descripcion: 'Vaso mezclador con rejilla',          precio: 25,  stock: 40, activo: false),
];
