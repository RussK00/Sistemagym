import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/api/socios_service.dart' show ApiException;
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/features/suplementos/models/producto.dart';

class ProductosService {
  ProductosService._();

  static final _base = '${ApiConfig.baseUrl}/productos';

  // GET /api/productos
  static Future<List<Producto>> listar() async {
    final res = await http
        .get(Uri.parse(_base), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return (jsonDecode(res.body) as List)
        .map((e) => Producto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /api/productos
  static Future<Producto> crear({
    required String nombre,
    required String descripcion,
    required String categoria,
    required double precio,
    required int stock,
    String imagenUrl = '',
  }) async {
    final res = await http
        .post(
          Uri.parse(_base),
          headers: Session.authHeaders,
          body: jsonEncode({
            'nombre': nombre, 'descripcion': descripcion, 'categoria': categoria,
            'precio': precio, 'stock': stock, 'imagen_url': imagenUrl,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 201) throw ApiException(_error(res.body));
    return Producto.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // PUT /api/productos/:id
  static Future<Producto> actualizar(int id, {
    required String nombre,
    required String descripcion,
    required String categoria,
    required double precio,
    required int stock,
    String imagenUrl = '',
  }) async {
    final res = await http
        .put(
          Uri.parse('$_base/$id'),
          headers: Session.authHeaders,
          body: jsonEncode({
            'nombre': nombre, 'descripcion': descripcion, 'categoria': categoria,
            'precio': precio, 'stock': stock, 'imagen_url': imagenUrl,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return Producto.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // POST /api/productos/imagen — sube una imagen (bytes) y devuelve su URL.
  // Usa bytes (no ruta) para que funcione también en Flutter Web, y envía el
  // Content-Type correcto para que el backend la reconozca como imagen.
  static Future<String> subirImagen(List<int> bytes, String filename) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/imagen'));
    req.headers['Authorization'] = 'Bearer ${Session.token}';
    req.files.add(http.MultipartFile.fromBytes('imagen', bytes,
        filename: filename, contentType: _tipoImagen(filename)));
    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(data['error'] as String? ?? 'Error al subir la imagen.');
    }
    return data['imagen_url'] as String;
  }

  static MediaType _tipoImagen(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':  return MediaType('image', 'png');
      case 'gif':  return MediaType('image', 'gif');
      case 'webp': return MediaType('image', 'webp');
      default:     return MediaType('image', 'jpeg'); // jpg/jpeg y fallback
    }
  }

  // PATCH /api/productos/:id/estado
  static Future<Producto> cambiarEstado(int id) async {
    final res = await http
        .patch(Uri.parse('$_base/$id/estado'), headers: Session.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw ApiException(_error(res.body));
    return Producto.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static String _error(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] as String? ?? 'Error en el servidor.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }
}
