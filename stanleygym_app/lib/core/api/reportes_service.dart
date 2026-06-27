import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/api/socios_service.dart' show ApiException;
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/features/asistencia/models/asistencia.dart';
import 'package:stanleygym_app/features/membresias/models/membresia.dart';

class ReportesService {
  ReportesService._();

  static final _base = '${ApiConfig.baseUrl}/reportes';

  // GET /api/reportes/dashboard — devuelve todo el JSON crudo del panel
  static Future<Map<String, dynamic>> dashboard() async {
    final res = await http
        .get(Uri.parse('$_base/dashboard'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // GET /api/reportes/asistencia?mes=&anio=
  static Future<List<Asistencia>> asistenciaMensual(int mes, int anio) async {
    final res = await http
        .get(Uri.parse('$_base/asistencia?mes=$mes&anio=$anio'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Asistencia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/reportes/membresias
  static Future<List<Membresia>> estadoMembresias() async {
    final res = await http
        .get(Uri.parse('$_base/membresias'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Membresia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String _error(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ?? 'Error en el servidor.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }
}
