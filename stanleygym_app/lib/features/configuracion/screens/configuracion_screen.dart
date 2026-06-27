import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/configuracion_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/core/widgets/accion_btn.dart';
import 'package:stanleygym_app/features/configuracion/models/cuenta_personal.dart';

// ─── Configuración (admin) — HU-13 (usuarios) + HU-14 (alertas) ───────────────

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Configuración',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.4)),
        Text('Administra las cuentas del personal y los parámetros del sistema.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
        const SizedBox(height: 20),
        _tabs(),
        const SizedBox(height: 20),
        Expanded(child: _tab == 0 ? const _UsuariosTab() : const _AlertasTab()),
      ]),
    );
  }

  Widget _tabs() {
    return Row(children: [
      _tabBtn(0, Icons.group_rounded,           'Recepcionistas'),
      const SizedBox(width: 8),
      _tabBtn(1, Icons.notifications_active_rounded, 'Alertas de vencimiento'),
    ]);
  }

  Widget _tabBtn(int index, IconData icon, String label) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.primary : AppColors.border2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: active ? Colors.white : AppColors.text2),
          const SizedBox(width: 7),
          Text(label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.text2)),
        ]),
      ),
    );
  }
}

// ─── HU-13: Gestión de recepcionistas ─────────────────────────────────────────

class _UsuariosTab extends StatefulWidget {
  const _UsuariosTab();

  @override
  State<_UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<_UsuariosTab> {
  List<CuentaPersonal> _cuentas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await ConfiguracionService.listarRecepcionistas();
      if (!mounted) return;
      setState(() { _cuentas = lista; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  void _crear() async {
    final datos = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CuentaFormDialog(),
    );
    if (datos == null) return;
    try {
      final nueva = await ConfiguracionService.crearRecepcionista(
        nombre:   datos['nombre']!,
        correo:   datos['correo']!,
        password: datos['password']!,
      );
      setState(() => _cuentas.insert(0, nueva));
      _snack('Cuenta de recepcionista creada correctamente.');
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  void _toggleActivo(CuentaPersonal c) async {
    try {
      final act = await ConfiguracionService.toggleRecepcionista(c.id);
      setState(() {
        final i = _cuentas.indexWhere((x) => x.id == c.id);
        if (i != -1) _cuentas[i] = act;
      });
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  void _eliminar(CuentaPersonal c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Eliminar cuenta',
          style: GoogleFonts.bricolageGrotesque(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          '¿Seguro que quieres eliminar la cuenta de "${c.nombre}"? '
          'Perderá el acceso al panel. Esta acción no se puede deshacer.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: AppColors.text2))),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('Eliminar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ConfiguracionService.eliminarRecepcionista(c.id);
      setState(() => _cuentas.removeWhere((x) => x.id == c.id));
      _snack('Cuenta eliminada correctamente.');
    } catch (e) {
      // Incluye el mensaje del backend si la cuenta tiene registros asociados.
      _snack(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activos = _cuentas.where((c) => c.activo).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('$activos activos · ${_cuentas.length} en total',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
        const Spacer(),
        FilledButton.icon(
          onPressed: _crear,
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: Text('Crear cuenta',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      Expanded(child: _contenido()),
    ]);
  }

  Widget _contenido() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.text3),
        const SizedBox(height: 10),
        Text(_error!, textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text('Reintentar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary)),
      ]));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: [
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              _th('Recepcionista', flex: 3),
              _th('Correo',        flex: 3),
              _th('Estado',        flex: 2),
              _th('Creada',        flex: 2),
              _th('',              flex: 2),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _cuentas.isEmpty
            ? Center(child: Text('No hay cuentas de recepcionista. Crea una con "Crear cuenta".',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3)))
            : ListView.separated(
                itemCount: _cuentas.length,
                separatorBuilder: (_, i) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) => _row(_cuentas[i]),
              )),
        ]),
      ),
    );
  }

  Widget _row(CuentaPersonal c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(c.inicial,
              style: GoogleFonts.bricolageGrotesque(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
          const SizedBox(width: 10),
          Flexible(child: Text(c.nombre,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.text),
            overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 3, child: Text(c.correo,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.activo ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                decoration: BoxDecoration(
                  color: c.activo ? AppColors.success : AppColors.text3, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(c.activo ? 'Activo' : 'Inactivo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: c.activo ? AppColors.success : AppColors.text2)),
            ]),
          ),
        )),
        Expanded(flex: 2, child: Text(_fmt(c.fechaCreacion),
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2))),
        Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          AccionBtn(
            icon: c.activo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            tooltip: c.activo ? 'Desactivar' : 'Activar',
            color: c.activo ? AppColors.danger : AppColors.success,
            onTap: () => _toggleActivo(c)),
          const SizedBox(width: 6),
          AccionBtn(
            icon: Icons.delete_outline_rounded, tooltip: 'Eliminar',
            color: AppColors.danger,
            onTap: () => _eliminar(c)),
        ])),
      ]),
    );
  }

  Widget _th(String label, {required int flex}) => Expanded(
    flex: flex,
    child: Text(label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 0.4)),
  );

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}

// ─── Formulario de cuenta ─────────────────────────────────────────────────────

class _CuentaFormDialog extends StatefulWidget {
  const _CuentaFormDialog();

  @override
  State<_CuentaFormDialog> createState() => _CuentaFormDialogState();
}

class _CuentaFormDialogState extends State<_CuentaFormDialog> {
  final _formKey  = GlobalKey<FormState>();
  final _nombre   = TextEditingController();
  final _correo   = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose(); _correo.dispose(); _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      'nombre':   _nombre.text.trim(),
      'correo':   _correo.text.trim(),
      'password': _password.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(key: _formKey, child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Crear cuenta de recepcionista',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
                Text('El recepcionista podrá acceder al panel web.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
              ])),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.text3)),
            ]),
            const SizedBox(height: 20),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),

            _label('Nombre completo *'),
            const SizedBox(height: 5),
            _field(_nombre, 'Ej: Ana Pérez Vela',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
            const SizedBox(height: 14),

            _label('Correo electrónico *'),
            const SizedBox(height: 5),
            _field(_correo, 'usuario@gmail.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim())) return 'Correo no válido';
                return null;
              }),
            const SizedBox(height: 14),

            _label('Contraseña temporal *'),
            const SizedBox(height: 5),
            _field(_password, 'Mínimo 6 caracteres',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (v.trim().length < 6) return 'Mínimo 6 caracteres';
                return null;
              }),

            const SizedBox(height: 22),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: AppColors.text2),
                child: Text('Cancelar',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500))),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text('Crear cuenta',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ]),
          ])),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text));

  Widget _field(TextEditingController c, String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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

// ─── HU-14: Configuración de alertas de vencimiento ───────────────────────────

class _AlertasTab extends StatefulWidget {
  const _AlertasTab();

  @override
  State<_AlertasTab> createState() => _AlertasTabState();
}

class _AlertasTabState extends State<_AlertasTab> {
  int  _dias = 3;
  bool _activas = true;
  int  _diasOrig = 3;
  bool _activasOrig = true;
  bool _loading = true;
  bool _guardando = false;
  bool _generando = false;
  String? _error;

  static const _opciones = [1, 2, 3, 5, 7, 10];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cfg = await ConfiguracionService.obtener();
      if (!mounted) return;
      setState(() {
        _dias        = cfg['dias_anticipacion'] as int;
        _activas     = cfg['notificaciones_activas'] as bool;
        _diasOrig    = _dias;
        _activasOrig = _activas;
        _loading     = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  bool get _hayCambios => _dias != _diasOrig || _activas != _activasOrig;

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await ConfiguracionService.guardar(dias: _dias, activas: _activas);
      if (!mounted) return;
      setState(() {
        _diasOrig = _dias; _activasOrig = _activas; _guardando = false;
      });
      _snack('Configuración guardada correctamente.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _generarAhora() async {
    setState(() => _generando = true);
    try {
      final n = await ConfiguracionService.generarNotificaciones();
      if (!mounted) return;
      setState(() => _generando = false);
      _snack(n == 0
          ? 'No hay membresías por vencer en el rango configurado.'
          : 'Se generaron $n notificación(es) para socios por vencer.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _generando = false);
      _snack(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.text3),
        const SizedBox(height: 10),
        Text(_error!, textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _cargar,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text('Reintentar', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ]));
    }
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Tarjeta: notificaciones activas
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Notificaciones automáticas',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 2),
                Text('Avisar al socio cuando su membresía esté por vencer.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
              ])),
              Switch(
                value: _activas,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _activas = v),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Tarjeta: días de anticipación
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.event_rounded, color: Color(0xFFD97706), size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Días de anticipación',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text('Cuántos días antes del vencimiento se enviará el aviso.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
                ])),
              ]),
              const SizedBox(height: 18),
              // Opciones de días
              Opacity(
                opacity: _activas ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !_activas,
                  child: Wrap(spacing: 10, runSpacing: 10,
                    children: _opciones.map((d) => _opcionDia(d)).toList()),
                ),
              ),
              const SizedBox(height: 18),
              // Vista previa del mensaje
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.text2),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    _activas
                        ? 'El socio recibirá la notificación $_dias ${_dias == 1 ? "día" : "días"} antes de que venza su membresía.'
                        : 'Las notificaciones automáticas están desactivadas.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2, height: 1.4)),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Botón guardar
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: (_hayCambios && !_guardando) ? _guardar : null,
              icon: _guardando
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(_guardando ? 'Guardando…' : 'Guardar cambios',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.border2,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Acción de demo: generar notificaciones ahora
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF7C3AED), size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Generar notificaciones ahora',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 2),
                Text('Revisa manualmente las membresías por vencer y crea los avisos. '
                     'El sistema también lo hace automáticamente cada día.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text2, height: 1.4)),
              ])),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _generando ? null : _generarAhora,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _generando
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Generar',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _opcionDia(int d) {
    final active = _dias == d;
    return GestureDetector(
      onTap: () => setState(() => _dias = d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : AppColors.border2, width: active ? 1.5 : 1),
        ),
        child: Column(children: [
          Text('$d',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22, fontWeight: FontWeight.w800,
              color: active ? AppColors.primary : AppColors.text, letterSpacing: -0.5, height: 1)),
          const SizedBox(height: 2),
          Text(d == 1 ? 'día' : 'días',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w500,
              color: active ? AppColors.primary : AppColors.text3)),
        ]),
      ),
    );
  }
}
