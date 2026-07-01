import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stanleygym_app/core/api/auth_service.dart';
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/core/auth/usuario_rol.dart';
import 'package:stanleygym_app/core/notifications/fcm_service.dart';
import 'package:stanleygym_app/features/auth/screens/login_screen.dart';
import 'package:stanleygym_app/features/dashboard/screens/admin_shell.dart';
import 'package:stanleygym_app/features/dashboard/screens/main_shell.dart';
import 'package:stanleygym_app/features/socio_app/screens/socio_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase solo se inicializa en móvil (la app del socio usa notificaciones push).
  // En web (panel del personal) no se usa FCM.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Si Firebase no está disponible, la app sigue funcionando sin push.
      debugPrint('Firebase no inicializado: $e');
    }
  }

  runApp(const StanleyGymApp());
}

class StanleyGymApp extends StatelessWidget {
  const StanleyGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StalinProGym',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  UsuarioSesion? _usuario;
  bool _cargando = true; // mientras se intenta restaurar la sesión guardada

  @override
  void initState() {
    super.initState();
    _restaurarSesion();
  }

  // "Recordarme": si hay un token guardado y sigue siendo válido, entra directo.
  Future<void> _restaurarSesion() async {
    final token = await Session.tokenGuardado();
    if (token != null) {
      final usuario = await AuthService.restaurarSesion(token);
      if (usuario != null) {
        Session.actual = usuario;
        if (usuario.rol == Rol.socio) FcmService.iniciarParaSocio();
        if (mounted) setState(() { _usuario = usuario; _cargando = false; });
        return;
      }
      await Session.clear(); // token inválido/expirado
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _onLogin(UsuarioSesion usuario, bool recordar) {
    Session.actual = usuario;
    if (recordar) Session.recordar();
    setState(() => _usuario = usuario);
    if (usuario.rol == Rol.socio) {
      FcmService.iniciarParaSocio();
    }
  }

  void _onLogout() {
    Session.clear();
    setState(() => _usuario = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Marca (mismo logo del login/sidebar)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  boxShadow: [BoxShadow(
                    color: Color(0x332563EB), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: SizedBox(
                  width: 74, height: 74,
                  child: Icon(Icons.fitness_center, color: Colors.white, size: 36),
                ),
              ),
              SizedBox(height: 20),
              Text('StalinProGym',
                style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A), letterSpacing: -0.5)),
              SizedBox(height: 6),
              Text('Cargando…',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              SizedBox(height: 28),
              SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ),
      );
    }
    final usuario = _usuario;
    if (usuario == null) {
      return LoginScreen(onLogin: _onLogin);
    }
    switch (usuario.rol) {
      case Rol.administrador:
        return AdminShell(usuario: usuario, onLogout: _onLogout);
      case Rol.socio:
        return SocioShell(usuario: usuario, onLogout: _onLogout);
      case Rol.recepcionista:
        return MainShell(onLogout: _onLogout);
    }
  }
}
