import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/socios_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/core/widgets/accion_btn.dart';
import 'package:stanleygym_app/features/socios/models/socio.dart';

// ─── SociosScreen ────────────────────────────────────────────────────────────

class SociosScreen extends StatefulWidget {
  const SociosScreen({super.key});

  @override
  State<SociosScreen> createState() => _SociosScreenState();
}

class _SociosScreenState extends State<SociosScreen> {
  List<Socio> _socios = [];
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await SociosService.listar();
      if (!mounted) return;
      setState(() { _socios = lista; _loading = false; });
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
    ));
  }

  List<Socio> get _filtered {
    if (_query.isEmpty) return _socios;
    final q = _query.toLowerCase();
    return _socios.where((s) =>
      s.nombreCompleto.toLowerCase().contains(q) ||
      s.dni.contains(q) ||
      s.correo.toLowerCase().contains(q),
    ).toList();
  }

  // Muestra las credenciales de acceso del socio recién creado.
  Future<void> _mostrarCredenciales(SocioCreado creado) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Text('Socio registrado',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3))),
              ]),
              const SizedBox(height: 16),
              Text('Se creó la cuenta de acceso a la app móvil. Entrega estas credenciales al socio:',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2, height: 1.4)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _credLinea(Icons.mail_outline, 'Usuario', creado.usuario),
                  const SizedBox(height: 12),
                  _credLinea(Icons.lock_outline, 'Contraseña inicial', creado.passwordInicial),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('La contraseña inicial es su DNI. El socio podrá cambiarla desde la app.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFFD97706), height: 1.3))),
                ]),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Entendido',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _credLinea(IconData icon, String label, String valor) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.text3),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.text2)),
        Text(valor, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
      ])),
    ]);
  }

  void _openForm({Socio? editing}) async {
    final datos = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SocioFormDialog(editing: editing),
    );
    if (datos == null) return;

    try {
      if (editing == null) {
        final creado = await SociosService.crear(
          nombres:   datos['nombres']!,
          apellidos: datos['apellidos']!,
          dni:       datos['dni']!,
          telefono:  datos['telefono']!,
          correo:    datos['correo']!,
        );
        setState(() => _socios.insert(0, creado.socio));
        if (mounted) await _mostrarCredenciales(creado);
      } else {
        final actualizado = await SociosService.actualizar(
          editing.id,
          nombres:   datos['nombres']!,
          apellidos: datos['apellidos']!,
          dni:       datos['dni']!,
          telefono:  datos['telefono']!,
          correo:    datos['correo']!,
        );
        setState(() {
          final i = _socios.indexWhere((s) => s.id == editing.id);
          if (i != -1) _socios[i] = actualizado;
        });
        _snack('Socio actualizado correctamente.');
      }
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  void _toggleEstado(Socio s) async {
    try {
      final actualizado = await SociosService.cambiarEstado(s.id);
      setState(() {
        final i = _socios.indexWhere((x) => x.id == s.id);
        if (i != -1) _socios[i] = actualizado;
      });
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 20),
          _toolbar(),
          const SizedBox(height: 16),
          Expanded(child: _contenido(filtered)),
        ],
      ),
    );
  }

  Widget _contenido(List<Socio> filtered) {
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
    return _table(filtered);
  }

  Widget _header() {
    final activos = _socios.where((s) => s.estado == 'activo').length;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Socios registrados',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: AppColors.text, letterSpacing: -0.4,
              ),
            ),
            Text(
              '$activos activos · ${_socios.length} en total',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2),
            ),
          ],
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: () => _openForm(),
          icon:  const Icon(Icons.person_add_rounded, size: 16),
          label: Text('Registrar socio',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _toolbar() {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _search,
        onChanged:  (v) => setState(() => _query = v),
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
        decoration: InputDecoration(
          hintText:  'Buscar por nombre, DNI o correo…',
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.text3),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _table(List<Socio> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            _tableHeader(),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: rows.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, i) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) => _tableRow(rows[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _th('Socio',    flex: 3),
          _th('DNI',      flex: 2),
          _th('Teléfono', flex: 2),
          _th('Correo',   flex: 3),
          _th('Estado',   flex: 2),
          _th('Registro', flex: 2),
          _th('',         flex: 2),
        ],
      ),
    );
  }

  Widget _th(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5, fontWeight: FontWeight.w600,
          color: AppColors.text2, letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _tableRow(Socio s) {
    final activo = s.estado == 'activo';
    final fecha  = '${s.fechaRegistro.day.toString().padLeft(2,'0')}/'
                   '${s.fechaRegistro.month.toString().padLeft(2,'0')}/'
                   '${s.fechaRegistro.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Nombre + avatar
          Expanded(flex: 3, child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                s.nombres[0],
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(
              s.nombreCompleto,
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.text),
              overflow: TextOverflow.ellipsis,
            )),
          ])),
          Expanded(flex: 2, child: _cell(s.dni)),
          Expanded(flex: 2, child: _cell(s.telefono)),
          Expanded(flex: 3, child: _cell(s.correo)),
          // Estado badge
          Expanded(flex: 2, child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        activo ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: activo ? AppColors.success : AppColors.text3,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  activo ? 'Activo' : 'Inactivo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: activo ? AppColors.success : AppColors.text2,
                  ),
                ),
              ]),
            ),
          )),
          Expanded(flex: 2, child: _cell(fecha)),
          // Acciones
          Expanded(flex: 2, child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AccionBtn(
                icon: Icons.edit_outlined, tooltip: 'Editar',
                onTap: () => _openForm(editing: s)),
              const SizedBox(width: 6),
              AccionBtn(
                icon: activo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                tooltip: activo ? 'Desactivar' : 'Activar',
                color: activo ? AppColors.danger : AppColors.success,
                onTap: () => _toggleEstado(s)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _cell(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.people_outline, size: 40, color: AppColors.text3),
        const SizedBox(height: 10),
        Text('No se encontraron socios',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.text2)),
      ]),
    );
  }
}

// ─── Formulario (Dialog) ─────────────────────────────────────────────────────

class _SocioFormDialog extends StatefulWidget {
  final Socio? editing;
  const _SocioFormDialog({this.editing});

  @override
  State<_SocioFormDialog> createState() => _SocioFormDialogState();
}

class _SocioFormDialogState extends State<_SocioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombres;
  late final TextEditingController _apellidos;
  late final TextEditingController _dni;
  late final TextEditingController _telefono;
  late final TextEditingController _correo;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nombres   = TextEditingController(text: e?.nombres   ?? '');
    _apellidos = TextEditingController(text: e?.apellidos ?? '');
    _dni       = TextEditingController(text: e?.dni       ?? '');
    _telefono  = TextEditingController(text: e?.telefono  ?? '');
    _correo    = TextEditingController(text: e?.correo    ?? '');
  }

  @override
  void dispose() {
    _nombres.dispose(); _apellidos.dispose();
    _dni.dispose(); _telefono.dispose(); _correo.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'nombres':   _nombres.text.trim(),
      'apellidos': _apellidos.text.trim(),
      'dni':       _dni.text.trim(),
      'telefono':  _telefono.text.trim(),
      'correo':    _correo.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      isEdit ? 'Editar socio' : 'Registrar nuevo socio',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Completa los datos personales del socio.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2),
                    ),
                  ])),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.text3),
                  ),
                ]),
                const SizedBox(height: 22),
                const Divider(color: AppColors.border),
                const SizedBox(height: 18),

                // Campos
                Row(children: [
                  Expanded(child: _field(label: 'Nombres *', ctrl: _nombres,
                    hint: 'Ej: Carlos Manuel',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: _field(label: 'Apellidos *', ctrl: _apellidos,
                    hint: 'Ej: Ríos Pérez',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  )),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _field(
                    label: 'DNI *', ctrl: _dni,
                    hint: '8 dígitos',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Campo requerido';
                      if (v.trim().length != 8) return 'Debe tener 8 dígitos';
                      return null;
                    },
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: _field(
                    label: 'Teléfono *', ctrl: _telefono,
                    hint: '9 dígitos',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Campo requerido';
                      if (v.trim().length < 9) return 'Mínimo 9 dígitos';
                      return null;
                    },
                  )),
                ]),
                const SizedBox(height: 14),
                _field(
                  label: 'Correo electrónico *', ctrl: _correo,
                  hint: 'ejemplo@correo.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Campo requerido';
                    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim())) return 'Correo no válido';
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: AppColors.text2),
                      child: Text('Cancelar',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon:  Icon(isEdit ? Icons.save_rounded : Icons.check_rounded, size: 16),
                      label: Text(
                        isEdit ? 'Guardar cambios' : 'Registrar socio',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text,
          )),
        const SizedBox(height: 5),
        TextFormField(
          controller:       ctrl,
          keyboardType:     keyboardType,
          inputFormatters:  inputFormatters,
          validator:        validator,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}
