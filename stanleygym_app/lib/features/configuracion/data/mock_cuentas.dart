import 'package:stanleygym_app/features/configuracion/models/cuenta_personal.dart';

// Cuentas de recepcionistas mock. En producción: GET /usuarios?rol=recepcionista
final mockCuentas = <CuentaPersonal>[
  CuentaPersonal(id: 1, nombre: 'Ana Pérez Vela',    correo: 'ana.perez@gmail.com',    activo: true,  fechaCreacion: DateTime(2025, 1, 15)),
  CuentaPersonal(id: 2, nombre: 'Luis Gómez Ríos',   correo: 'luis.gomez@gmail.com',   activo: true,  fechaCreacion: DateTime(2025, 3, 8)),
  CuentaPersonal(id: 3, nombre: 'Rosa Díaz Mori',    correo: 'rosa.diaz@gmail.com',    activo: false, fechaCreacion: DateTime(2024, 11, 20)),
];
