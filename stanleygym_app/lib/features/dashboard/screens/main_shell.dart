import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/core/widgets/foto_perfil_editable.dart';
import 'package:stanleygym_app/features/socios/screens/socios_screen.dart';
import 'package:stanleygym_app/features/membresias/screens/membresias_screen.dart';
import 'package:stanleygym_app/features/asistencia/screens/checkin_screen.dart';
import 'package:stanleygym_app/features/pagos/screens/pagos_screen.dart';
import 'package:stanleygym_app/features/ventas/screens/ventas_screen.dart';
import 'package:stanleygym_app/features/cuenta/screens/mi_cuenta_screen.dart';

// ─── Modelo de ítem de navegación ────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String   label;
  final Widget   screen;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

// ─── MainShell ───────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainShell({super.key, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selected = 0;

  final List<_NavItem> _items = [
    _NavItem(icon: Icons.people_alt_rounded,  label: 'Socios',     screen: const SociosScreen()),
    _NavItem(icon: Icons.card_membership,     label: 'Membresías', screen: const MembresiasScreen()),
    _NavItem(icon: Icons.how_to_reg_rounded,  label: 'Check-in',   screen: const CheckinScreen()),
    _NavItem(icon: Icons.payments_rounded,    label: 'Pagos',      screen: const PagosScreen()),
    _NavItem(icon: Icons.shopping_cart_rounded, label: 'Compras',  screen: const VentasScreen()),
    _NavItem(icon: Icons.account_circle_rounded, label: 'Mi cuenta', screen: const MiCuentaScreen()),
  ];

  // Sin ítems futuros para el recepcionista (su menú está completo).
  final List<_NavItem> _future = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          _Sidebar(
            items:       _items,
            futureItems: _future,
            selected:    _selected,
            onSelect:    (i) => setState(() => _selected = i),
            onLogout:    widget.onLogout,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: _items[_selected].label),
                // IndexedStack mantiene las secciones cargadas → cambio instantáneo.
                Expanded(child: IndexedStack(
                  index: _selected,
                  children: _items.map((e) => e.screen).toList(),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final List<_NavItem> futureItems;
  final int            selected;
  final ValueChanged<int> onSelect;
  final VoidCallback   onLogout;

  const _Sidebar({
    required this.items,
    required this.futureItems,
    required this.selected,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [AppColors.navyDark, AppColors.navy, AppColors.navyDeep],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        children: [
          _logo(),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1E293B), thickness: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
          // Sección principal
          _sectionLabel('PRINCIPAL'),
          ...items.asMap().entries.map((e) => _NavTile(
            item:     e.value,
            isActive: e.key == selected,
            onTap:    () => onSelect(e.key),
          )),
          if (futureItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionLabel('PRÓXIMAMENTE'),
            ...futureItems.map((item) => _NavTile(item: item, isActive: false, onTap: () {})),
          ],
          const Spacer(),
          const Divider(color: Color(0xFF1E293B), thickness: 1, indent: 16, endIndent: 16),
          _logoutTile(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _logo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              boxShadow: [BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12, offset: const Offset(0, 4),
              )],
            ),
            child: const Icon(Icons.fitness_center, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'StalinProGym',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _logoutTile() {
    return InkWell(
      onTap: onLogout,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF64748B)),
            const SizedBox(width: 10),
            Text(
              'Cerrar sesión',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── NavTile ─────────────────────────────────────────────────────────────────

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
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                if (isActive)
                  Container(
                    width: 3, height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                if (isActive) const SizedBox(width: 8),
                Icon(item.icon, size: 18, color: isActive ? AppColors.accentBlue : color),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── TopBar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                AvatarPerfil(
                  fotoUrl: Session.actual?.fotoUrl,
                  inicial: Session.actual?.inicial ?? 'R',
                  radius: 12),
                const SizedBox(width: 8),
                Text(
                  'Recepcionista',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
