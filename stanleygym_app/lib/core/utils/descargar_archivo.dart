// Punto de entrada: usa la implementación web si está disponible, si no el stub.
export 'descargar_stub.dart'
    if (dart.library.html) 'descargar_web.dart';
