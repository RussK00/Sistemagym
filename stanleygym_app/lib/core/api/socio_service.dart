import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/api/socios_service.dart' show ApiException;
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/features/asistencia/models/asistencia.dart';
import 'package:stanleygym_app/features/membresias/models/membresia.dart';
import 'package:stanleygym_app/features/socio_app/models/notificacion.dart';
import 'package:stanleygym_app/features/socios/models/socio.dart';

/// Servicios de la app móvil del socio (devuelven solo SUS datos).
class SocioService {
  SocioService._();

  static final _base = '${ApiConfig.baseUrl}/socio';

  // GET /api/socio/mi-membresia — puede devolver null si no tiene
  static Future<Membresia?> miMembresia() async {
    final res = await http
        .get(Uri.parse('$_base/mi-membresia'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    final data = jsonDecode(res.body);
    if (data == null) return null;
    return Membresia.fromJson(data as Map<String, dynamic>);
  }

  // GET /api/socio/mi-asistencia
  static Future<List<Asistencia>> miAsistencia() async {
    final res = await http
        .get(Uri.parse('$_base/mi-asistencia'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Asistencia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/socio/mis-notificaciones
  static Future<List<Notificacion>> misNotificaciones() async {
    final res = await http
        .get(Uri.parse('$_base/mis-notificaciones'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Notificacion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/socio/mi-perfil
  static Future<Socio> miPerfil() async {
    final res = await http
        .get(Uri.parse('$_base/mi-perfil'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return Socio.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // PATCH /api/socio/notificaciones/:id/leida
  static Future<void> marcarLeida(int id) async {
    final res = await http
        .patch(Uri.parse('$_base/notificaciones/$id/leida'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
  }

  static String _error(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ?? 'Error en el servidor.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }
}
