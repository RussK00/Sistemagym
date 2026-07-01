import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/auth/usuario_rol.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/socio_app/screens/historial_asistencia_screen.dart';
import 'package:stanleygym_app/features/socio_app/screens/mi_cuenta_socio_screen.dart';
import 'package:stanleygym_app/features/socio_app/screens/mi_membresia_screen.dart';
import 'package:stanleygym_app/features/socio_app/screens/socio_home_screen.dart';

// ─── SocioShell ──────────────────────────────────────────────────────────────
// Simula la app móvil del socio dentro de un marco de celular cuando se ve en web.

class SocioShell extends StatelessWidget {
  final UsuarioSesion usuario;
  final VoidCallback onLogout;
  const SocioShell({super.key, required this.usuario, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: LayoutBuilder(
        builder: (context, cs) {
          // En pantallas anchas (web) lo mostramos en un marco de celular centrado.
          final useFrame = cs.maxWidth > 600;

          final app = _SocioApp(usuario: usuario, onLogout: onLogout);

          if (!useFrame) return app;

          return Center(
            child: Container(
              width: 390,
              height: 800,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFF1E293B), width: 10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: app,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── App interna con navegación inferior ──────────────────────────────────────

class _SocioApp extends StatefulWidget {
  final UsuarioSesion usuario;
  final VoidCallback onLogout;
  const _SocioApp({required this.usuario, required this.onLogout});

  @override
  State<_SocioApp> createState() => _SocioAppState();
}

class _SocioAppState extends State<_SocioApp> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      SocioHomeScreen(
        usuario: widget.usuario,
        onNavigate: (i) => setState(() => _index = i),
      ),
      MiMembresiaScreen(usuario: widget.usuario, onLogout: widget.onLogout),
      HistorialAsistenciaScreen(usuario: widget.usuario),
      MiCuentaSocioScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      // IndexedStack mantiene las pantallas cargadas: se cargan una vez y al
      // cambiar de pestaña aparecen al instante (sin volver a mostrar el spinner).
      body: SafeArea(child: IndexedStack(index: _index, children: screens)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              labelTextStyle: WidgetStatePropertyAll(
                GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child: NavigationBar(
              height: 64,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.card_membership_outlined),
                  selectedIcon: Icon(Icons.card_membership, color: AppColors.primary),
                  label: 'Membresía',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
                  label: 'Asistencia',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_circle_outlined),
                  selectedIcon: Icon(Icons.account_circle, color: AppColors.primary),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

