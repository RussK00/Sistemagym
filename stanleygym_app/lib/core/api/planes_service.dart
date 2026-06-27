import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/api/socios_service.dart' show ApiException;
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/features/membresias/models/plan.dart';

class PlanesService {
  PlanesService._();

  static final _base = '${ApiConfig.baseUrl}/planes';

  // GET /api/planes  (todos=true → incluye inactivos, para la gestión del admin)
  static Future<List<Plan>> listar({bool todos = false}) async {
    final uri = Uri.parse(todos ? '$_base?todos=true' : _base);
    final res = await http.get(uri, headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /api/planes
  static Future<Plan> crear({
    required String nombre,
    required int duracionDias,
    required double precio,
    required String descripcion,
    required List<String> caracteristicas,
  }) async {
    final res = await http.post(Uri.parse(_base),
        headers: Session.authHeaders,
        body: jsonEncode({
          'nombre': nombre, 'duracion_dias': duracionDias,
          'precio': precio, 'descripcion': descripcion,
          'caracteristicas': caracteristicas,
        })).timeout(const Duration(seconds: 10));
    if (res.statusCode != 201) throw ApiException(_error(res.body));
    return Plan.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // PUT /api/planes/:id
  static Future<Plan> actualizar(int id, {
    required String nombre,
    required int duracionDias,
    required double precio,
    required String descripcion,
    required List<String> caracteristicas,
  }) async {
    final res = await http.put(Uri.parse('$_base/$id'),
        headers: Session.authHeaders,
        body: jsonEncode({
          'nombre': nombre, 'duracion_dias': duracionDias,
          'precio': precio, 'descripcion': descripcion,
          'caracteristicas': caracteristicas,
        })).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return Plan.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // PATCH /api/planes/:id/estado
  static Future<Plan> cambiarEstado(int id) async {
    final res = await http.patch(Uri.parse('$_base/$id/estado'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return Plan.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // DELETE /api/planes/:id
  static Future<void> eliminar(int id) async {
    final res = await http.delete(Uri.parse('$_base/$id'), headers: Session.authHeaders)
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
