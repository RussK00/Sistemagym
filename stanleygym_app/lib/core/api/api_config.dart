import 'package:flutter/foundation.dart';

/// Configuración base de la API.
///
/// Por defecto usa el backend desplegado en Render (producción), así la app
/// y el panel web funcionan en línea sin necesidad de correr el backend local.
///
/// Para desarrollar con el backend LOCAL (más rápido), cambia [_usarLocal] a
/// true. En el emulador Android, `localhost` no apunta a tu PC; se usa la IP
/// especial 10.0.2.2.
class ApiConfig {
  ApiConfig._();

  /// Backend en línea (Render).
  static const _produccion = 'https://sistemagym-api.onrender.com/api';

  /// Cambia a `true` para usar el backend local (http://localhost:3000).
  static const _usarLocal = false;

  static String get baseUrl {
    if (!_usarLocal) return _produccion;

    // ─── Desarrollo local ───
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api'; // emulador Android → PC anfitriona
    }
    return 'http://localhost:3000/api';
  }
}
