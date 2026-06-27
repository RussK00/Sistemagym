import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/api/socios_service.dart' show ApiException;
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/features/asistencia/models/asistencia.dart';

class AsistenciaService {
  AsistenciaService._();

  static final _base = '${ApiConfig.baseUrl}/asistencia';

  // GET /api/asistencia/hoy
  static Future<List<Asistencia>> ingresosHoy() async {
    final res = await http
        .get(Uri.parse('$_base/hoy'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Asistencia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /api/asistencia
  static Future<Asistencia> registrar(int idSocio) async {
    final res = await http
        .post(
          Uri.parse(_base),
          headers: Session.authHeaders,
          body: jsonEncode({'id_socio': idSocio}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 201) throw ApiException(_error(res.body));
    return Asistencia.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static String _error(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ?? 'Error en el servidor.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }
}
