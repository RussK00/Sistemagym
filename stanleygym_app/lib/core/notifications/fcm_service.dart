import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:stanleygym_app/core/api/api_config.dart';
import 'package:stanleygym_app/core/auth/session.dart';

/// Maneja las notificaciones push (Firebase Cloud Messaging) para el socio.
class FcmService {
  FcmService._();

  /// Inicializa FCM tras el login del socio:
  /// pide permiso, obtiene el token del dispositivo y lo registra en el backend.
  static Future<void> iniciarParaSocio() async {
    if (kIsWeb) return; // FCM solo en la app móvil del socio

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Pedir permiso de notificaciones (Android 13+ e iOS)
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // 2. Obtener el token del dispositivo y enviarlo al backend
      final token = await messaging.getToken();
      if (token != null) {
        await _registrarToken(token);
      }

      // 3. Si el token se renueva, volver a registrarlo
      messaging.onTokenRefresh.listen(_registrarToken);

      // 4. Mensajes recibidos con la app en primer plano
      FirebaseMessaging.onMessage.listen((mensaje) {
        debugPrint('Push en primer plano: ${mensaje.notification?.title}');
      });
    } catch (e) {
      debugPrint('Error iniciando FCM: $e');
    }
  }

  static Future<void> _registrarToken(String token) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/socio/token-fcm'),
        headers: Session.authHeaders,
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 10));
      debugPrint('Token FCM registrado en el backend.');
    } catch (e) {
      debugPrint('No se pudo registrar el token FCM: $e');
    }
  }
}
