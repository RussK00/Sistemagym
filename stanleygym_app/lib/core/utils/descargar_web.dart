// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Descarga un archivo en el navegador (Flutter Web) usando un data URI.
void descargarArchivo(String contenido, String nombre, String mime) {
  final dataUri = 'data:$mime;charset=utf-8,${Uri.encodeComponent(contenido)}';
  html.AnchorElement(href: dataUri)
    ..setAttribute('download', nombre)
    ..click();
}
