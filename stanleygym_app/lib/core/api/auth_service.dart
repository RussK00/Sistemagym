import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/core/auth/usuario_rol.dart';
import 'package:stanleygym_app/features/cuenta/models/cuenta_info.dart';

class LoginResult {
  final UsuarioSesion? usuario;
  final String?        error;
  const LoginResult({this.usuario, this.error});
}

class AuthService {
  AuthService._();

  /// Restaura la sesión a partir de un token guardado ("Recordarme").
  /// Valida el token contra el backend; si es válido devuelve el usuario.
  static Future<UsuarioSesion?> restaurarSesion(String token) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null; // token inválido o expirado
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return UsuarioSesion.fromJson(data['usuario'] as Map<String, dynamic>, token);
    } catch (_) {
      return null; // sin conexión, etc.
    }
  }

  /// Inicia sesión contra el backend real.
  /// - Web   → solo personal (administrador / recepcionista)
  /// - Móvil → solo socios
  static Future<LoginResult> login(
    String correo,
    String password, {
    required bool esWeb,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'correo': correo.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // Error devuelto por el backend (credenciales, cuenta inactiva, etc.)
      if (res.statusCode != 200) {
        return LoginResult(error: data['error'] as String? ?? 'Error al iniciar sesión.');
      }

      final usuario = UsuarioSesion.fromJson(
        data['usuario'] as Map<String, dynamic>,
        data['token'] as String,
      );

      // Restricción por plataforma (según la documentación del proyecto)
      final esSocio = usuario.rol == Rol.socio;
      if (esWeb && esSocio) {
        return const LoginResult(
          error: 'Esta cuenta es de socio. Inicia sesión desde la app móvil de StalinProGym.');
      }
      if (!esWeb && !esSocio) {
        return const LoginResult(
          error: 'El personal accede desde el panel web en la computadora del gimnasio.');
      }

      return LoginResult(usuario: usuario);
    } catch (e) {
      // Errores de red / servidor caído / timeout
      return const LoginResult(
        error: 'No se pudo conectar con el servidor. Verifica que el backend esté corriendo.');
    }
  }

  /// Obtiene los datos completos de la cuenta autenticada (GET /auth/me).
  static Future<CuentaInfo> miCuenta() async {
    final res = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/auth/me'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(data['error'] as String? ?? 'No se pudo obtener la cuenta.');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return CuentaInfo.fromJson(data['usuario'] as Map<String, dynamic>);
  }

  /// Sube una foto de perfil. Devuelve la URL pública, o lanza excepción.
  static Future<String> subirFoto(String filePath) async {
    final req = http.MultipartRequest(
      'POST', Uri.parse('${ApiConfig.baseUrl}/auth/foto'));
    req.headers['Authorization'] = 'Bearer ${Session.token}';
    req.files.add(await http.MultipartFile.fromPath('foto', filePath));

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(data['error'] as String? ?? 'Error al subir la foto.');
    }
    return data['foto_url'] as String;
  }

  /// Cambia la contraseña del usuario autenticado.
  /// Devuelve null si fue exitoso, o el mensaje de error.
  static Future<String?> cambiarPassword(String actual, String nueva) async {
    try {
      final res = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/auth/cambiar-password'),
            headers: Session.authHeaders,
            body: jsonEncode({'actual': actual, 'nueva': nueva}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['error'] as String? ?? 'Error al cambiar la contraseña.';
    } catch (e) {
      return 'No se pudo conectar con el servidor.';
    }
  }
}
