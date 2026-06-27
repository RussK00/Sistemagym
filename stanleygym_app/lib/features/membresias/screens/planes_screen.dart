import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/planes_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/core/widgets/accion_btn.dart';
import 'package:stanleygym_app/features/membresias/models/plan.dart';

// ─── Gestión de planes de membresía (administrador) ───────────────────────────

class PlanesScreen extends StatefulWidget {
  const PlanesScreen({super.key});

  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

class _PlanesScreenState extends State<PlanesScreen> {
  List<Plan> _planes = [];
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await PlanesService.listar(todos: true);
      if (!mounted) return;
      setState(() { _planes = lista; _loading = false; });
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

  void _openForm({Plan? editing}) async {
    final datos = await showDialog<Map<String, dynamic>>(
      context: context, barrierDismissible: false,
      builder: (_) => _PlanFormDialog(editing: editing),
    );
    if (datos == null) return;
    try {
      if (editing == null) {
        final nuevo = await PlanesService.crear(
          nombre:          datos['nombre'] as String,
          duracionDias:    datos['duracionDias'] as int,
          precio:          datos['precio'] as double,
          descripcion:     datos['descripcion'] as String,
          caracteristicas: datos['caracteristicas'] as List<String>,
        );
        setState(() => _planes.add(nuevo));
        _snack('Plan creado correctamente.');
      } else {
        final actualizado = await PlanesService.actualizar(editing.id,
          nombre:          datos['nombre'] as String,
          duracionDias:    datos['duracionDias'] as int,
          precio:          datos['precio'] as double,
          descripcion:     datos['descripcion'] as String,
          caracteristicas: datos['caracteristicas'] as List<String>,
        );
        setState(() {
          final i = _planes.indexWhere((p) => p.id == editing.id);
          if (i != -1) {
            // Conservar el conteo de socios (el update no lo recalcula)
            _planes[i] = Plan(
              id: actualizado.id, nombre: actualizado.nombre,
              duracionDias: actualizado.duracionDias, precio: actualizado.precio,
              descripcion: actualizado.descripcion, activo: actualizado.activo,
              caracteristicas: actualizado.caracteristicas,
              sociosActivos: _planes[i].sociosActivos);
          }
        });
        _snack('Plan actualizado correctamente.');
      }
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  void _toggle(Plan p) async {
    try {
      final act = await PlanesService.cambiarEstado(p.id);
      setState(() {
        final i = _planes.indexWhere((x) => x.id == p.id);
        if (i != -1) {
          _planes[i] = Plan(
            id: act.id, nombre: act.nombre, duracionDias: act.duracionDias,
            precio: act.precio, descripcion: act.descripcion, activo: act.activo,
            caracteristicas: act.caracteristicas, sociosActivos: _planes[i].sociosActivos);
        }
      });
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  void _eliminar(Plan p) async {
    // Confirmación
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Eliminar plan',
          style: GoogleFonts.bricolageGrotesque(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text('¿Seguro que quieres eliminar el plan "${p.nombre}"? Esta acción no se puede deshacer.',
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
      await PlanesService.eliminar(p.id);
      setState(() => _planes.removeWhere((x) => x.id == p.id));
      _snack('Plan eliminado correctamente.');
    } catch (e) {
      // Aquí llega el mensaje "No puedes eliminar... tiene socios activos"
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
        FilledButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text('Reintentar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary)),
      ]));
    }

    final activos = _planes.where((p) => p.activo).toList();
    final totalSocios = _planes.fold(0, (s, p) => s + p.sociosActivos);
    final idMasPopular = _idPlanMasPopular(activos);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Encabezado
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Planes de Membresía',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.6)),
            const SizedBox(height: 2),
            Text('$totalSocios socios activos en ${activos.length} planes.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)),
          ])),
          FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text('Nuevo Plan', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
        const SizedBox(height: 24),

        // Tarjetas (solo planes activos)
        Wrap(spacing: 16, runSpacing: 16,
          children: activos.map((p) => _planCard(p, p.id == idMasPopular)).toList()),
        const SizedBox(height: 28),

        // Tabla con todos los planes
        _tabla(),
      ]),
    );
  }

  int? _idPlanMasPopular(List<Plan> activos) {
    if (activos.isEmpty) return null;
    Plan top = activos.first;
    for (final p in activos) {
      if (p.sociosActivos > top.sociosActivos) top = p;
    }
    return top.sociosActivos > 0 ? top.id : null;
  }

  // ── Tarjeta de plan ──────────────────────────────────────────────────────

  Widget _planCard(Plan p, bool popular) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: popular ? AppColors.primary : AppColors.border, width: popular ? 1.6 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Badge "MÁS POPULAR"
        if (popular)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
            child: Text('MÁS POPULAR', textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nombre,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(p.descripcion.isEmpty ? '${p.duracionDias} días de acceso' : p.descripcion,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
            const SizedBox(height: 14),
            // Precio
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('S/ ', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
              Text(p.precio.toStringAsFixed(0),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -1.5, height: 1)),
              const SizedBox(width: 4),
              Text('/ ${_periodo(p.duracionDias)}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text3)),
            ]),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            // Características
            ...p.caracteristicas.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(child: Text(c,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text, height: 1.3))),
              ]),
            )),
            if (p.caracteristicas.isEmpty)
              Text('Sin características definidas.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text3)),
            const SizedBox(height: 6),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            // Socios activos
            Row(children: [
              Text('Socios activos',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
              const Spacer(),
              Text('${p.sociosActivos}',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            ]),
            const SizedBox(height: 14),
            // Botones
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _openForm(editing: p),
                icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.text2),
                label: Text('Editar', style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text2)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: AppColors.border2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _toggle(p),
                icon: const Icon(Icons.visibility_off_rounded, size: 14, color: AppColors.danger),
                label: Text('Desactivar', style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.danger)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── Tabla "Todos los planes" ───────────────────────────────────────────────

  Widget _tabla() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Todos los planes',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.text3, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${_planes.length} planes',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _th('PLAN', flex: 3), _th('PRECIO', flex: 2), _th('DURACIÓN', flex: 2),
            _th('SOCIOS ACTIVOS', flex: 2), _th('ESTADO', flex: 2), _th('ACCIONES', flex: 3),
          ]),
          const Divider(height: 20, color: AppColors.border),
          ..._planes.map(_filaTabla),
        ]),
      ),
    );
  }

  Widget _filaTabla(Plan p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Text(p.nombre,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text))),
        Expanded(flex: 2, child: Text('S/ ${p.precio.toStringAsFixed(0)}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text))),
        Expanded(flex: 2, child: Text('${p.duracionDias} días',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2))),
        Expanded(flex: 2, child: Text('${p.sociosActivos}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text))),
        Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: p.activo ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(
              color: p.activo ? AppColors.success : AppColors.text3, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(p.activo ? 'Activo' : 'Inactivo', style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5, fontWeight: FontWeight.w600, color: p.activo ? AppColors.success : AppColors.text2)),
          ]),
        ))),
        Expanded(flex: 3, child: Row(children: [
          AccionBtn(
            icon: Icons.edit_outlined, tooltip: 'Editar',
            onTap: () => _openForm(editing: p)),
          const SizedBox(width: 6),
          AccionBtn(
            icon: p.activo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            tooltip: p.activo ? 'Desactivar' : 'Activar',
            color: p.activo ? AppColors.danger : AppColors.success,
            onTap: () => _toggle(p)),
          const SizedBox(width: 6),
          AccionBtn(
            icon: Icons.delete_outline_rounded, tooltip: 'Eliminar',
            color: AppColors.danger,
            onTap: () => _eliminar(p)),
        ])),
      ]),
    );
  }

  Widget _th(String t, {required int flex}) => Expanded(flex: flex,
    child: Text(t, style: GoogleFonts.plusJakartaSans(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 0.4)));

  String _periodo(int dias) {
    if (dias == 30)  return 'mes';
    if (dias == 90)  return '3 meses';
    if (dias == 180) return '6 meses';
    if (dias == 365) return 'año';
    return '$dias días';
  }
}

// ─── Formulario de plan ───────────────────────────────────────────────────────

class _PlanFormDialog extends StatefulWidget {
  final Plan? editing;
  const _PlanFormDialog({this.editing});

  @override
  State<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<_PlanFormDialog> {
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _duracion;
  late final TextEditingController _precio;
  late final TextEditingController _desc;
  late final TextEditingController _caract;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nombre   = TextEditingController(text: e?.nombre ?? '');
    _duracion = TextEditingController(text: e?.duracionDias.toString() ?? '');
    _precio   = TextEditingController(text: e?.precio.toStringAsFixed(0) ?? '');
    _desc     = TextEditingController(text: e?.descripcion ?? '');
    _caract   = TextEditingController(text: (e?.caracteristicas ?? []).join('\n'));
  }

  @override
  void dispose() {
    _nombre.dispose(); _duracion.dispose(); _precio.dispose(); _desc.dispose(); _caract.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final caracteristicas = _caract.text
        .split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    Navigator.of(context).pop({
      'nombre':          _nombre.text.trim(),
      'duracionDias':    int.parse(_duracion.text.trim()),
      'precio':          double.parse(_precio.text.trim()),
      'descripcion':     _desc.text.trim(),
      'caracteristicas': caracteristicas,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(key: _formKey, child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.card_membership, color: AppColors.primary, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isEdit ? 'Editar plan' : 'Nuevo plan',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
                  Text('Datos del plan de membresía.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
                ])),
                IconButton(onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.text3)),
              ]),
              const SizedBox(height: 20),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),

              _label('Nombre del plan *'),
              const SizedBox(height: 5),
              _field(_nombre, 'Ej: Mensual',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Duración (días) *'),
                  const SizedBox(height: 5),
                  _field(_duracion, '30',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) return 'Inválido';
                      return null;
                    }),
                ])),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Precio (S/.) *'),
                  const SizedBox(height: 5),
                  _field(_precio, '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      if (n == null || n < 0) return 'Inválido';
                      return null;
                    }),
                ])),
              ]),
              const SizedBox(height: 14),

              _label('Descripción'),
              const SizedBox(height: 5),
              _field(_desc, 'Ej: Acceso flexible mes a mes'),
              const SizedBox(height: 14),

              _label('Características (una por línea)'),
              const SizedBox(height: 5),
              _field(_caract, 'Acceso ilimitado al gimnasio\nCasillero gratuito\n1 clase grupal por semana',
                maxLines: 5),

              const SizedBox(height: 22),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: AppColors.text2),
                  child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500))),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(isEdit ? Icons.save_rounded : Icons.check_rounded, size: 16),
                  label: Text(isEdit ? 'Guardar cambios' : 'Crear plan',
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
      ),
    );
  }

  Widget _label(String t) => Text(t,
    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text));

  Widget _field(TextEditingController c, String hint, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
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
