import 'package:flutter/foundation.dart';

/// Configuración base de la API según la plataforma.
///
/// IMPORTANTE — el emulador Android no usa `localhost`:
/// - En el emulador Android, `localhost` apunta al propio emulador, NO a tu PC.
///   Para llegar a tu PC (donde corre el backend) se usa la IP especial 10.0.2.2.
/// - En Flutter Web (Chrome) sí se usa localhost normal.
class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    if (kIsWeb) {
      // Navegador (panel web del personal)
      return 'http://localhost:3000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Emulador Android → 10.0.2.2 es el "localhost" de la PC anfitriona
      return 'http://10.0.2.2:3000/api';
    }
    // iOS, Windows, etc.
    return 'http://localhost:3000/api';
  }
}
