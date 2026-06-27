/// Genera el contenido de un archivo CSV a partir de encabezados y filas.
///
/// - Usa punto y coma (;) como separador: así Excel en español separa
///   correctamente las columnas (en locale ES, la coma es decimal).
/// - Antepone un BOM UTF-8 (﻿) para que Excel muestre bien las tildes/ñ.
String generarCsv(List<String> encabezados, List<List<String>> filas) {
  const sep = ';';
  final buffer = StringBuffer();
  buffer.write('﻿'); // BOM UTF-8
  buffer.writeln(encabezados.map(_escapar).join(sep));
  for (final fila in filas) {
    buffer.writeln(fila.map(_escapar).join(sep));
  }
  return buffer.toString();
}

String _escapar(String campo) {
  if (campo.contains(';') || campo.contains('"') || campo.contains('\n')) {
    return '"${campo.replaceAll('"', '""')}"';
  }
  return campo;
}
