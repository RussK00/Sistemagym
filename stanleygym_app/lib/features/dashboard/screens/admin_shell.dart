import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/auth/usuario_rol.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/core/widgets/foto_perfil_editable.dart';
import 'package:stanleygym_app/features/dashboard/screens/home_screen.dart';
import 'package:stanleygym_app/features/membresias/screens/planes_screen.dart';
import 'package:stanleygym_app/features/reportes/screens/reportes_screen.dart';
import 'package:stanleygym_app/features/suplementos/screens/suplementos_screen.dart';
import 'package:stanleygym_app/features/configuracion/screens/configuracion_screen.dart';
import 'package:stanleygym_app/features/ventas/screens/historial_compras_screen.dart';
import 'package:stanleygym_app/features/cuenta/screens/mi_cuenta_screen.dart';

class _NavItem {
  final IconData icon;
  final String   label;
  final Widget   screen;
  const _NavItem({required this.icon, required this.label, required this.screen});
}

class AdminShell extends StatefulWidget {
  final UsuarioSesion usuario;
  final VoidCallback  onLogout;
  const AdminShell({super.key, required this.usuario, required this.onLogout});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selected = 0;

  final List<_NavItem> _items = [
    _NavItem(icon: Icons.dashboard_rounded,   label: 'Panel',       screen: const HomeScreen()),
    _NavItem(icon: Icons.card_membership,     label: 'Planes',      screen: const PlanesScreen()),
    _NavItem(icon: Icons.bar_chart_rounded,   label: 'Reportes',    screen: const ReportesScreen()),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Productos', screen: const SuplementosScreen()),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Hist. compras', screen: const HistorialComprasScreen()),
    _NavItem(icon: Icons.settings_rounded,    label: 'Configuración', screen: const ConfiguracionScreen()),
    _NavItem(icon: Icons.account_circle_rounded, label: 'Mi cuenta', screen: const MiCuentaScreen()),
  ];

  final List<_NavItem> _future = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        _buildSidebar(),
        Expanded(child: Column(children: [
          _buildTopBar(),
          // IndexedStack mantiene las secciones cargadas → cambio instantáneo.
          Expanded(child: IndexedStack(
            index: _selected,
            children: _items.map((e) => e.screen).toList(),
          )),
        ])),
      ]),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.navyDark, AppColors.navy, AppColors.navyDeep],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(children: [
        _logo(),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFF1E293B), thickness: 1, indent: 16, endIndent: 16),
        const SizedBox(height: 8),
        _sectionLabel('ADMINISTRACIÓN'),
        ...(_items.asMap().entries.map((e) => _NavTile(
          item: e.value, isActive: e.key == _selected,
          onTap: () => setState(() => _selected = e.key),
        ))),
        if (_future.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('PRÓXIMAMENTE'),
          ..._future.map((item) => _NavTile(item: item, isActive: false, onTap: () {})),
        ],
        const Spacer(),
        const Divider(color: Color(0xFF1E293B), thickness: 1, indent: 16, endIndent: 16),
        InkWell(
          onTap: widget.onLogout,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 10),
              Text('Cerrar sesión',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B))),
            ]),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _logo() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark]),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.fitness_center, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 10),
      Text('StalinProGym',
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
    ]),
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: const Color(0xFF475569), letterSpacing: 1.1)),
    ),
  );

  Widget _buildTopBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Text(_items[_selected].label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            AvatarPerfil(
              fotoUrl: widget.usuario.fotoUrl,
              inicial: widget.usuario.inicial,
              radius: 12,
              bgColor: const Color(0xFF7C3AED)),
            const SizedBox(width: 8),
            Text(widget.usuario.rolLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
          ]),
        ),
      ]),
    );
  }
}

// ─── NavTile reutilizable ─────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool     isActive;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.white : const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isActive ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(children: [
              if (isActive) ...[
                Container(width: 3, height: 18,
                  decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
              ],
              Icon(item.icon, size: 18, color: isActive ? AppColors.accentBlue : color),
              const SizedBox(width: 10),
              Text(item.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: color)),
            ]),
          ),
        ),
      ),
    );
  }
}
