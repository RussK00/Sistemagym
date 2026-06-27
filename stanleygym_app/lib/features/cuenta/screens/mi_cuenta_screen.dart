import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/auth_service.dart';
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/core/widgets/foto_perfil_editable.dart';
import 'package:stanleygym_app/features/cuenta/models/cuenta_info.dart';

// ─── Mi cuenta — perfil personal del recepcionista ────────────────────────────
// El recepcionista solo puede cambiar su foto y su contraseña. El resto de los
// datos (nombre, correo, rol, estado) los gestiona el administrador.

class MiCuentaScreen extends StatefulWidget {
  const MiCuentaScreen({super.key});

  @override
  State<MiCuentaScreen> createState() => _MiCuentaScreenState();
}

class _MiCuentaScreenState extends State<MiCuentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actual  = TextEditingController();
  final _nueva   = TextEditingController();
  final _repetir = TextEditingController();
  bool _guardando = false;
  bool _verActual = false, _verNueva = false, _verRepetir = false;

  CuentaInfo? _cuenta;
  bool _cargandoCuenta = true;

  @override
  void initState() {
    super.initState();
    _cargarCuenta();
  }

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _repetir.dispose();
    super.dispose();
  }

  Future<void> _cargarCuenta() async {
    try {
      final c = await AuthService.miCuenta();
      if (!mounted) return;
      setState(() { _cuenta = c; _cargandoCuenta = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoCuenta = false); // se usa el fallback de sesión
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final error = await AuthService.cambiarPassword(_actual.text, _nueva.text);
    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      _snack(error, error: true);
      return;
    }
    _actual.clear(); _nueva.clear(); _repetir.clear();
    _snack('Contraseña actualizada correctamente.');
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final u = Session.actual;
    final nombre = _cuenta?.nombre   ?? u?.nombre   ?? '—';
    final correo = _cuenta?.correo   ?? u?.correo   ?? '—';
    final rol    = _cuenta?.rolLabel ?? u?.rolLabel ?? '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mi cuenta',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.4)),
          Text('Consulta tus datos, cambia tu foto y tu contraseña.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
          const SizedBox(height: 24),

          // ── Tarjeta de perfil (foto + nombre + rol) ─────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              FotoPerfilEditable(radius: 36, onActualizada: () => setState(() {})),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nombre,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(correo,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                      child: Text(rol,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 8),
                    _estadoBadge(),
                  ]),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.photo_camera_outlined, size: 14, color: AppColors.text3),
            const SizedBox(width: 6),
            Text('Toca la foto para subir o cambiar tu imagen de perfil.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text3)),
          ]),
          const SizedBox(height: 24),

          // ── Datos de la cuenta (solo lectura) ───────────────────────
          Row(children: [
            Text('Datos de la cuenta',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bg, borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline_rounded, size: 11, color: AppColors.text3),
                const SizedBox(width: 4),
                Text('Solo lectura',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.text3)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          _datosCard(nombre, correo, rol),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.text3),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                rol == 'Administrador'
                    ? 'Estos datos forman parte de la configuración del sistema.'
                    : 'Estos datos los gestiona el administrador. Si algo está incorrecto, contáctalo.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text3)),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Seguridad: cambiar contraseña ───────────────────────────
          Text('Seguridad',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text('Cambia tu contraseña de acceso.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
          const SizedBox(height: 14),
          _passwordCard(),
        ]),
      ),
    );
  }

  // ─── Badge de estado de cuenta ────────────────────────────────────────────

  Widget _estadoBadge() {
    if (_cargandoCuenta) {
      return const SizedBox(
        width: 12, height: 12,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.text3));
    }
    final activo = _cuenta?.activo ?? true;
    final color = activo ? AppColors.success : AppColors.danger;
    final bg    = activo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(activo ? 'Activo' : 'Inactivo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // ─── Card de datos de la cuenta (solo lectura) ────────────────────────────

  Widget _datosCard(String nombre, String correo, String rol) {
    final fecha = _cuenta?.fechaCreacion;
    final estado = (_cuenta?.activo ?? true) ? 'Activo' : 'Inactivo';

    final filas = <Widget>[
      _filaDato(Icons.person_outline_rounded, 'Nombre de usuario', nombre),
      _filaDato(Icons.mail_outline_rounded,   'Correo electrónico', correo),
      _filaDato(Icons.badge_outlined,         'Rol', rol),
      _filaDato(Icons.verified_user_outlined, 'Estado de la cuenta',
          _cargandoCuenta ? '…' : estado),
      _filaDato(Icons.calendar_today_rounded, 'Cuenta creada el',
          _cargandoCuenta ? '…' : (fecha != null ? _fmtFecha(fecha) : '—')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: List.generate(filas.length, (i) {
        final last = i == filas.length - 1;
        return Column(children: [
          filas[i],
          if (!last) const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
        ]);
      })),
    );
  }

  Widget _filaDato(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
        ),
        Flexible(
          child: Text(valor,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text)),
        ),
      ]),
    );
  }

  // ─── Card de cambio de contraseña ─────────────────────────────────────────

  Widget _passwordCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Contraseña actual *'),
        const SizedBox(height: 5),
        _field(_actual, _verActual, () => setState(() => _verActual = !_verActual),
          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null),
        const SizedBox(height: 14),

        _label('Nueva contraseña *'),
        const SizedBox(height: 5),
        _field(_nueva, _verNueva, () => setState(() => _verNueva = !_verNueva),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingresa la nueva contraseña';
            if (v.length < 6) return 'Mínimo 6 caracteres';
            return null;
          }),
        const SizedBox(height: 14),

        _label('Repetir nueva contraseña *'),
        const SizedBox(height: 5),
        _field(_repetir, _verRepetir, () => setState(() => _verRepetir = !_verRepetir),
          validator: (v) {
            if (v != _nueva.text) return 'Las contraseñas no coinciden';
            return null;
          }),
        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _guardando ? null : _cambiarPassword,
            icon: _guardando
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_reset_rounded, size: 16),
            label: Text(_guardando ? 'Guardando…' : 'Cambiar contraseña',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ])),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtFecha(DateTime d) {
    const meses = ['enero','febrero','marzo','abril','mayo','junio',
                   'julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }

  Widget _label(String t) => Text(t,
    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text));

  Widget _field(TextEditingController c, bool visible, VoidCallback toggle, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      obscureText: !visible,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: const TextStyle(color: AppColors.text3),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.text3),
          onPressed: toggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
      ),
    );
  }
}
