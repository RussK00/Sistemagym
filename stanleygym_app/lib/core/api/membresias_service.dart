import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/api/socios_service.dart' show ApiException;
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/features/membresias/models/membresia.dart';
import 'package:stanleygym_app/features/membresias/models/plan.dart';

class MembresiasService {
  MembresiasService._();

  static final _baseMem    = '${ApiConfig.baseUrl}/membresias';
  static final _basePlanes = '${ApiConfig.baseUrl}/planes';

  // GET /api/planes
  static Future<List<Plan>> listarPlanes() async {
    final res = await http
        .get(Uri.parse(_basePlanes), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/membresias
  static Future<List<Membresia>> listar() async {
    final res = await http
        .get(Uri.parse(_baseMem), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Membresia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /api/membresias
  static Future<Membresia> crear({
    required int idSocio,
    required int idPlan,
    required DateTime fechaInicio,
    required String metodoPago,
  }) async {
    final fecha = '${fechaInicio.year}-'
        '${fechaInicio.month.toString().padLeft(2, '0')}-'
        '${fechaInicio.day.toString().padLeft(2, '0')}';

    final res = await http
        .post(
          Uri.parse(_baseMem),
          headers: Session.authHeaders,
          body: jsonEncode({
            'id_socio': idSocio,
            'id_plan': idPlan,
            'fecha_inicio': fecha,
            'metodo_pago': metodoPago,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 201) throw ApiException(_error(res.body));
    return Membresia.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static String _error(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ?? 'Error en el servidor.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }
}
