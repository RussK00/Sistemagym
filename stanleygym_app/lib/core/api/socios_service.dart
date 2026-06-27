import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/features/socios/models/socio.dart';

/// Excepción simple para mostrar mensajes de error de la API.
class ApiException implements Exception {
  final String mensaje;
  ApiException(this.mensaje);
  @override
  String toString() => mensaje;
}

/// Resultado de crear un socio: el socio + sus credenciales de acceso.
class SocioCreado {
  final Socio  socio;
  final String usuario;
  final String passwordInicial;
  const SocioCreado({required this.socio, required this.usuario, required this.passwordInicial});
}

class SociosService {
  SociosService._();

  static final _base = '${ApiConfig.baseUrl}/socios';

  // GET /api/socios
  static Future<List<Socio>> listar() async {
    final res = await http
        .get(Uri.parse(_base), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw ApiException(_error(res.body));
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Socio.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST /api/socios — crea el socio + su cuenta de acceso
  static Future<SocioCreado> crear({
    required String nombres,
    required String apellidos,
    required String dni,
    required String telefono,
    required String correo,
  }) async {
    final res = await http
        .post(
          Uri.parse(_base),
          headers: Session.authHeaders,
          body: jsonEncode({
            'nombres': nombres, 'apellidos': apellidos, 'dni': dni,
            'telefono': telefono, 'correo': correo,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 201) throw ApiException(_error(res.body));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final acceso = j['acceso'] as Map<String, dynamic>?;
    return SocioCreado(
      socio:           Socio.fromJson(j),
      usuario:         acceso?['usuario'] as String? ?? correo,
      passwordInicial: acceso?['passwordInicial'] as String? ?? dni,
    );
  }

  // PUT /api/socios/:id
  static Future<Socio> actualizar(int id, {
    required String nombres,
    required String apellidos,
    required String dni,
    required String telefono,
    required String correo,
  }) async {
    final res = await http
        .put(
          Uri.parse('$_base/$id'),
          headers: Session.authHeaders,
          body: jsonEncode({
            'nombres': nombres, 'apellidos': apellidos, 'dni': dni,
            'telefono': telefono, 'correo': correo,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return Socio.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // PATCH /api/socios/:id/estado
  static Future<Socio> cambiarEstado(int id) async {
    final res = await http
        .patch(Uri.parse('$_base/$id/estado'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return Socio.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static String _error(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ?? 'Error en el servidor.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }
}
