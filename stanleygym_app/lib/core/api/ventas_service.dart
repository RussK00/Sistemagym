import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/api/socios_service.dart' show ApiException;
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/features/ventas/models/venta.dart';

class VentasService {
  VentasService._();

  static final _base = '${ApiConfig.baseUrl}/ventas';

  // GET /api/ventas
  static Future<List<Venta>> listar() async {
    final res = await http
        .get(Uri.parse(_base), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Venta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/ventas/socio/:id  (HU-11 admin / HU-12 socio)
  static Future<List<Venta>> porSocio(int idSocio) async {
    final res = await http
        .get(Uri.parse('$_base/socio/$idSocio'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Venta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /api/ventas
  static Future<Venta> crear({
    required int idSocio,
    required int idProducto,
    required int cantidad,
  }) async {
    final res = await http
        .post(
          Uri.parse(_base),
          headers: Session.authHeaders,
          body: jsonEncode({
            'id_socio': idSocio,
            'id_producto': idProducto,
            'cantidad': cantidad,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 201) throw ApiException(_error(res.body));
    return Venta.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static String _error(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ?? 'Error en el servidor.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }
}
