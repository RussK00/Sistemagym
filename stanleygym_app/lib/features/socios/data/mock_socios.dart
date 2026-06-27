import 'package:stanleygym_app/features/socios/models/socio.dart';

final mockSocios = <Socio>[
  Socio(id: 1, nombres: 'Carlos', apellidos: 'Ríos Pérez',   dni: '45123678', telefono: '965432100', correo: 'carlos.rios@gmail.com',    estado: 'activo',   fechaRegistro: DateTime(2025, 1, 10)),
  Socio(id: 2, nombres: 'María',  apellidos: 'Torres Lomas', dni: '52876543', telefono: '974321987', correo: 'maria.torres@hotmail.com', estado: 'activo',   fechaRegistro: DateTime(2025, 2, 14)),
  Socio(id: 3, nombres: 'Jhon',   apellidos: 'Sánchez Ruiz', dni: '61234987', telefono: '956789012', correo: 'jhon.sanchez@gmail.com',   estado: 'inactivo', fechaRegistro: DateTime(2025, 3,  5)),
];
