import 'package:stanleygym_app/features/asistencia/models/asistencia.dart';

// Historial de asistencia mock (compartido entre reportes admin y app del socio).
// En producción vendría del backend: GET /asistencia?id_socio=X
final mockAsistencia = <Asistencia>[
  // Carlos Ríos (idSocio: 1) — asiste con frecuencia
  Asistencia(id: 1,  idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  planSocio: 'Mensual',    fechaHoraIngreso: DateTime(2026, 6,  2, 8, 10)),
  Asistencia(id: 2,  idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  planSocio: 'Mensual',    fechaHoraIngreso: DateTime(2026, 6,  4, 7, 45)),
  Asistencia(id: 3,  idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  planSocio: 'Mensual',    fechaHoraIngreso: DateTime(2026, 6,  6, 18, 30)),
  Asistencia(id: 4,  idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  planSocio: 'Mensual',    fechaHoraIngreso: DateTime(2026, 6,  7, 8, 0)),
  Asistencia(id: 5,  idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  planSocio: 'Mensual',    fechaHoraIngreso: DateTime(2026, 5, 28, 9, 15)),
  Asistencia(id: 6,  idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  planSocio: 'Mensual',    fechaHoraIngreso: DateTime(2026, 5, 25, 7, 50)),
  Asistencia(id: 7,  idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  planSocio: 'Mensual',    fechaHoraIngreso: DateTime(2026, 5, 22, 19, 0)),
  Asistencia(id: 8,  idSocio: 1, nombreSocio: 'Carlos Ríos Pérez',  planSocio: 'Mensual',    fechaHoraIngreso: DateTime(2026, 5, 20, 8, 20)),
  // María Torres (idSocio: 2)
  Asistencia(id: 9,  idSocio: 2, nombreSocio: 'María Torres Lomas', planSocio: 'Trimestral', fechaHoraIngreso: DateTime(2026, 6,  3, 9, 30)),
  Asistencia(id: 10, idSocio: 2, nombreSocio: 'María Torres Lomas', planSocio: 'Trimestral', fechaHoraIngreso: DateTime(2026, 6,  5, 8, 40)),
  Asistencia(id: 11, idSocio: 2, nombreSocio: 'María Torres Lomas', planSocio: 'Trimestral', fechaHoraIngreso: DateTime(2026, 5, 30, 10, 0)),
  // Jhon Sánchez (idSocio: 3)
  Asistencia(id: 12, idSocio: 3, nombreSocio: 'Jhon Sánchez Ruiz',  planSocio: 'Mensual',    fechaHoraIngreso: DateTime(2026, 5, 15, 11, 5)),
];
