import 'package:shared_preferences/shared_preferences.dart';
import 'package:stanleygym_app/core/auth/usuario_rol.dart';

/// Guarda la sesión activa (usuario + token JWT) de forma global,
/// para que los servicios HTTP puedan adjuntar el token en cada petición.
/// También persiste el token en disco cuando el usuario marca "Recordarme".
class Session {
  Session._();

  static UsuarioSesion? actual;

  static String? get token => actual?.token;

  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static const _kToken = 'auth_token';

  /// Guarda el token en disco (solo si el usuario marcó "Recordarme").
  static Future<void> recordar() async {
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token!);
  }

  /// Devuelve el token guardado en disco (o null si no hay).
  static Future<String?> tokenGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  /// Cierra la sesión: limpia memoria y disco.
  static Future<void> clear() async {
    actual = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
  }
}
