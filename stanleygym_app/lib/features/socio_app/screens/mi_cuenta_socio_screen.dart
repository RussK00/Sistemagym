import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/auth_service.dart';
import 'package:stanleygym_app/core/api/socio_service.dart';
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/socios/models/socio.dart';

// ─── Perfil del socio ─────────────────────────────────────────────────────────

class MiCuentaSocioScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MiCuentaSocioScreen({super.key, required this.onLogout});

  @override
  State<MiCuentaSocioScreen> createState() => _MiCuentaSocioScreenState();
}

class _MiCuentaSocioScreenState extends State<MiCuentaSocioScreen> {
  Socio? _perfil;
  bool _notificaciones = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final p = await SocioService.miPerfil();
      if (!mounted) return;
      setState(() { _perfil = p; });
    } catch (_) {
      // si falla, muestra solo los datos de sesión disponibles
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final u = Session.actual;
    final nombre = u?.nombre ?? '—';
    final correo = u?.correo ?? '—';
    final iniciales = _iniciales(nombre);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Perfil',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 24, fontWeight: FontWeight.w800,
              color: AppColors.text, letterSpacing: -0.5)),
          const SizedBox(height: 24),

          // ── Avatar centrado ─────────────────────────────────────────
          Center(child: _avatar(iniciales)),
          const SizedBox(height: 14),
          Center(
            child: Text(nombre,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: AppColors.text, letterSpacing: -0.4)),
          ),
          if (_perfil != null) ...[
            const SizedBox(height: 6),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.badge_outlined,
                    size: 14, color: AppColors.text3),
                const SizedBox(width: 4),
                Text(
                  'DNI ${_fmtDni(_perfil!.dni)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: AppColors.text3)),
              ]),
            ),
          ],
          const SizedBox(height: 24),

          // ── Información personal ────────────────────────────────────
          _seccionLabel('Información personal'),
          const SizedBox(height: 10),
          _infoCard(correo),
          const SizedBox(height: 20),

          // ── Configuración ───────────────────────────────────────────
          _seccionLabel('Configuración'),
          const SizedBox(height: 10),
          _configCard(context),
          const SizedBox(height: 24),

          // ── Cerrar sesión ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded,
                  size: 18, color: AppColors.danger),
              label: Text('Cerrar sesión',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.danger)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Avatar con borde en gradiente ────────────────────────────────────────

  Widget _avatar(String iniciales) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentBlue, AppColors.primaryDark],
        ),
      ),
      padding: const EdgeInsets.all(3), // aro de gradiente
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(3), // aro blanco
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.navyDeep,
          ),
          child: Center(
            child: Text(iniciales,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 24, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: -0.5)),
          ),
        ),
      ),
    );
  }

  // ─── Card de información personal ─────────────────────────────────────────

  Widget _infoCard(String correo) {
    final p = _perfil;
    final rows = <_InfoRow>[
      if (p != null && p.telefono.isNotEmpty)
        _InfoRow(Icons.phone_rounded, 'Teléfono', p.telefono),
      _InfoRow(Icons.mail_outline_rounded, 'Correo', correo),
      if (p != null)
        _InfoRow(Icons.calendar_today_rounded, 'Miembro desde',
            _fmtFecha(p.fechaRegistro)),
    ];

    if (rows.isEmpty) {
      // Fallback mientras carga o si falla el perfil
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: _infoFila(
            _InfoRow(Icons.mail_outline_rounded, 'Correo', correo), true),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final last = i == rows.length - 1;
          return Column(children: [
            _infoFila(rows[i], last),
            if (!last)
              const Divider(height: 1, color: AppColors.border,
                  indent: 16, endIndent: 16),
          ]);
        }),
      ),
    );
  }

  Widget _infoFila(_InfoRow r, bool last) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(r.icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5, color: AppColors.text3)),
            Text(r.valor,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text)),
          ]),
        ),
      ]),
    );
  }

  // ─── Card de configuración ────────────────────────────────────────────────

  Widget _configCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        // Notificaciones toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notificaciones',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text)),
                Text('Recordatorios y alertas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppColors.text3)),
              ],
            )),
            Switch(
              value: _notificaciones,
              onChanged: (v) => setState(() => _notificaciones = v),
              thumbColor: const WidgetStatePropertyAll(Colors.white),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.primary;
                return AppColors.border2;
              }),
              trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border,
            indent: 16, endIndent: 16),

        // Cambiar perfil / contraseña
        InkWell(
          onTap: () => _abrirCambiarPerfil(context),
          borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cambiar contraseña',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5, fontWeight: FontWeight.w600,
                      color: AppColors.text)),
                  Text('Actualiza tu contraseña',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: AppColors.text3)),
                ],
              )),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.text3, size: 20),
            ]),
          ),
        ),
      ]),
    );
  }

  void _abrirCambiarPerfil(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _CambiarPerfilScreen(onLogout: widget.onLogout),
    ));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _seccionLabel(String texto) {
    return Text(texto,
      style: GoogleFonts.bricolageGrotesque(
        fontSize: 14, fontWeight: FontWeight.w700,
        color: AppColors.text2, letterSpacing: -0.2));
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  String _fmtDni(String dni) {
    if (dni.length == 8) {
      return '${dni.substring(0, 2)} ${dni.substring(2, 5)} ${dni.substring(5)}';
    }
    return dni;
  }

  String _fmtFecha(DateTime d) {
    const meses = ['Ene','Feb','Mar','Abr','May','Jun',
                   'Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }
}

// ─── Modelos locales ──────────────────────────────────────────────────────────

class _InfoRow {
  final IconData icon;
  final String label;
  final String valor;
  const _InfoRow(this.icon, this.label, this.valor);
}

// ─── Pantalla: Cambiar perfil / contraseña ────────────────────────────────────

class _CambiarPerfilScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const _CambiarPerfilScreen({required this.onLogout});

  @override
  State<_CambiarPerfilScreen> createState() => _CambiarPerfilScreenState();
}

class _CambiarPerfilScreenState extends State<_CambiarPerfilScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _actual   = TextEditingController();
  final _nueva    = TextEditingController();
  final _repetir  = TextEditingController();
  bool _guardando  = false;
  bool _verActual  = false;
  bool _verNueva   = false;
  bool _verRepetir = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _repetir.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final error = await AuthService.cambiarPassword(_actual.text, _nueva.text);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      _snack(error, isError: true);
      return;
    }
    _actual.clear(); _nueva.clear(); _repetir.clear();
    _snack('Contraseña actualizada correctamente.');
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Cambiar perfil',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 17, fontWeight: FontWeight.w700,
            color: AppColors.text, letterSpacing: -0.3)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ingresa tu contraseña actual y la nueva que deseas usar.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppColors.primary)),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              Text('Contraseña',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.text, letterSpacing: -0.3)),
              const SizedBox(height: 14),

              Form(
                key: _formKey,
                child: Column(children: [
                  _campo(
                    controller: _actual,
                    hint: 'Contraseña actual',
                    visible: _verActual,
                    onToggle: () => setState(() => _verActual = !_verActual),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Ingresa tu contraseña actual' : null,
                  ),
                  const SizedBox(height: 12),
                  _campo(
                    controller: _nueva,
                    hint: 'Nueva contraseña',
                    visible: _verNueva,
                    onToggle: () => setState(() => _verNueva = !_verNueva),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa la nueva contraseña';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _campo(
                    controller: _repetir,
                    hint: 'Repetir nueva contraseña',
                    visible: _verRepetir,
                    onToggle: () => setState(() => _verRepetir = !_verRepetir),
                    validator: (v) =>
                        v != _nueva.text ? 'Las contraseñas no coinciden' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _guardando ? null : _cambiar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.lock_reset_rounded, size: 18),
                      label: Text(
                        _guardando ? 'Guardando…' : 'Cambiar contraseña',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13.5, color: AppColors.text3),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18, color: AppColors.text3),
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border2)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
      ),
    );
  }
}
