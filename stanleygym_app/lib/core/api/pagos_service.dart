import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/api/socios_service.dart' show ApiException;
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/features/pagos/models/pago.dart';

class PagosService {
  PagosService._();

  static final _base = '${ApiConfig.baseUrl}/pagos';

  // GET /api/pagos
  static Future<List<Pago>> listar() async {
    final res = await http
        .get(Uri.parse(_base), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Pago.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /api/pagos
  static Future<Pago> crear({
    required int idSocio,
    required String concepto,
    required double monto,
    required DateTime fechaPago,
    required String metodoPago,
  }) async {
    final fecha = '${fechaPago.year}-'
        '${fechaPago.month.toString().padLeft(2, '0')}-'
        '${fechaPago.day.toString().padLeft(2, '0')}';

    final res = await http
        .post(
          Uri.parse(_base),
          headers: Session.authHeaders,
          body: jsonEncode({
            'id_socio': idSocio,
            'concepto': concepto,
            'monto': monto,
            'fecha_pago': fecha,
            'metodo_pago': metodoPago,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 201) throw ApiException(_error(res.body));
    return Pago.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static String _error(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ?? 'Error en el servidor.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }
}
