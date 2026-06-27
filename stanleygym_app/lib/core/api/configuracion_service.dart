import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/api/socios_service.dart' show ApiException;
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/features/configuracion/models/cuenta_personal.dart';

class ConfiguracionService {
  ConfiguracionService._();

  static final _base = '${ApiConfig.baseUrl}/configuracion';

  // ─── Cuentas de recepcionista ────────────────────────────────────────────

  // GET /api/configuracion/recepcionistas
  static Future<List<CuentaPersonal>> listarRecepcionistas() async {
    final res = await http
        .get(Uri.parse('$_base/recepcionistas'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => CuentaPersonal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /api/configuracion/recepcionistas
  static Future<CuentaPersonal> crearRecepcionista({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/recepcionistas'),
          headers: Session.authHeaders,
          body: jsonEncode({'nombre': nombre, 'correo': correo, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 201) throw ApiException(_error(res.body));
    return CuentaPersonal.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // PATCH /api/configuracion/recepcionistas/:id/estado
  static Future<CuentaPersonal> toggleRecepcionista(int id) async {
    final res = await http
        .patch(Uri.parse('$_base/recepcionistas/$id/estado'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return CuentaPersonal.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // DELETE /api/configuracion/recepcionistas/:id
  static Future<void> eliminarRecepcionista(int id) async {
    final res = await http
        .delete(Uri.parse('$_base/recepcionistas/$id'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
  }

  // GET /api/configuracion
  static Future<Map<String, dynamic>> obtener() async {
    final res = await http
        .get(Uri.parse(_base), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return {
      'dias_anticipacion':      j['dias_anticipacion'] as int,
      'notificaciones_activas': j['notificaciones_activas'] as bool,
    };
  }

  // PUT /api/configuracion
  static Future<void> guardar({
    required int dias,
    required bool activas,
  }) async {
    final res = await http
        .put(
          Uri.parse(_base),
          headers: Session.authHeaders,
          body: jsonEncode({
            'dias_anticipacion': dias,
            'notificaciones_activas': activas,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
  }

  // POST /api/notificaciones/generar — dispara la generación (demo)
  static Future<int> generarNotificaciones() async {
    final res = await http
        .post(Uri.parse('${ApiConfig.baseUrl}/notificaciones/generar'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as Map<String, dynamic>)['creadas'] as int? ?? 0;
  }

  static String _error(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ?? 'Error en el servidor.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }
}
