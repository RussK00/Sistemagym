import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/membresias_service.dart';
import 'package:stanleygym_app/core/api/socios_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/membresias/models/membresia.dart';
import 'package:stanleygym_app/features/membresias/models/plan.dart';
import 'package:stanleygym_app/features/socios/models/socio.dart';

// ─── MembresiasScreen ────────────────────────────────────────────────────────

class MembresiasScreen extends StatefulWidget {
  const MembresiasScreen({super.key});

  @override
  State<MembresiasScreen> createState() => _MembresiasScreenState();
}

class _MembresiasScreenState extends State<MembresiasScreen> {
  List<Membresia> _membresias = [];
  List<Socio>     _socios     = [];
  List<Plan>      _planes     = [];
  final TextEditingController _search = TextEditingController();
  String _query  = '';
  String _filtro = 'Todos'; // Todos | activa | vencida | por vencer
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
      final results = await Future.wait([
        MembresiasService.listar(),
        SociosService.listar(),
        MembresiasService.listarPlanes(),
      ]);
      if (!mounted) return;
      setState(() {
        _membresias = results[0] as List<Membresia>;
        _socios     = results[1] as List<Socio>;
        _planes     = results[2] as List<Plan>;
        _loading    = false;
      });
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

  List<Membresia> get _filtered {
    return _membresias.where((m) {
      final matchQ = _query.isEmpty ||
          m.nombreSocio.toLowerCase().contains(_query.toLowerCase()) ||
          m.nombrePlan.toLowerCase().contains(_query.toLowerCase());

      final estado = m.estadoEfectivo;
      final matchF = _filtro == 'Todos' ||
          (_filtro == 'activa'     && estado == 'activa' && m.diasRestantes > 7) ||
          (_filtro == 'por vencer' && estado == 'activa' && m.diasRestantes <= 7) ||
          (_filtro == 'vencida'    && estado == 'vencida');

      return matchQ && matchF;
    }).toList();
  }

  // Solo deja renovar cuando la membresía ya terminó (vencida/suspendida).
  // Si aún está vigente, avisa hasta qué fecha debe esperar.
  void _intentarRenovar(Membresia m) {
    if (m.estadoEfectivo == 'activa') {
      String fmt(DateTime d) =>
          '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
      _snack(
        'Esta membresía aún está vigente (vence el ${fmt(m.fechaVencimiento)}, '
        'le quedan ${m.diasRestantes} días). Podrás renovarla cuando termine.',
        error: true,
      );
      return;
    }
    _openForm(renovando: m);
  }

  void _openForm({Membresia? renovando}) async {
    // IDs de socios que ya tienen una membresía activa (para bloquear duplicados).
    final sociosConActiva = _membresias
        .where((m) => m.estadoEfectivo == 'activa')
        .map((m) => m.idSocio)
        .toSet();

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MembresiaFormDialog(
        socios:          _socios,
        planes:          _planes,
        renovando:       renovando,
        sociosConActiva: sociosConActiva,
      ),
    );

    if (datos == null) return;
    try {
      final nueva = await MembresiasService.crear(
        idSocio:     datos['idSocio'] as int,
        idPlan:      datos['idPlan'] as int,
        fechaInicio: datos['fechaInicio'] as DateTime,
        metodoPago:  datos['metodoPago'] as String,
      );
      setState(() {
        // Reemplaza la membresía vigente del mismo socio (o la agrega)
        final i = _membresias.indexWhere((m) => m.idSocio == nueva.idSocio);
        if (i != -1) {
          _membresias[i] = nueva;
        } else {
          _membresias.insert(0, nueva);
        }
      });
      _snack(renovando != null ? 'Membresía renovada correctamente.' : 'Membresía asignada correctamente.');
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activas    = _membresias.where((m) => m.estadoEfectivo == 'activa').length;
    final porVencer  = _membresias.where((m) => m.estadoEfectivo == 'activa' && m.diasRestantes <= 7).length;
    final vencidas   = _membresias.where((m) => m.estadoEfectivo == 'vencida').length;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),
          _resumenChips(activas, porVencer, vencidas),
          const SizedBox(height: 16),
          _toolbar(),
          const SizedBox(height: 16),
          Expanded(child: _contenido(filtered)),
        ],
      ),
    );
  }

  Widget _contenido(List<Membresia> filtered) {
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
    return Row(
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Membresías',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.text, letterSpacing: -0.4)),
          Text('Asigna, renueva y controla el estado de las membresías.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
        ]),
        const Spacer(),
        FilledButton.icon(
          onPressed: () => _openForm(),
          icon:  const Icon(Icons.add_rounded, size: 16),
          label: Text('Asignar membresía',
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

  Widget _resumenChips(int activas, int porVencer, int vencidas) {
    return Wrap(spacing: 10, children: [
      _chip('Todos',      '${_membresias.length}', AppColors.text2,       const Color(0xFFF1F5F9)),
      _chip('activa',     '$activas',               AppColors.success,     const Color(0xFFDCFCE7)),
      _chip('por vencer', '$porVencer',             AppColors.warning,     const Color(0xFFFEF3C7)),
      _chip('vencida',    '$vencidas',              AppColors.danger,      const Color(0xFFFEE2E2)),
    ]);
  }

  Widget _chip(String label, String count, Color color, Color bg) {
    final active = _filtro == label;
    return GestureDetector(
      onTap: () => setState(() => _filtro = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        active ? color.withValues(alpha: 0.15) : bg,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: active ? color : Colors.transparent, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label == 'Todos' ? 'Todos' : label[0].toUpperCase() + label.substring(1),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5, fontWeight: FontWeight.w600,
              color: active ? color : AppColors.text2)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Text(count,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
      ),
    );
  }

  Widget _toolbar() {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
        decoration: InputDecoration(
          hintText:  'Buscar por socio o plan…',
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.text3),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border2)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary)),
        ),
      ),
    );
  }

  Widget _table(List<Membresia> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: [
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
        ]),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        _th('Socio',       flex: 3),
        _th('Plan',        flex: 2),
        _th('Inicio',      flex: 2),
        _th('Vencimiento', flex: 2),
        _th('Estado',      flex: 2),
        _th('Días rest.',  flex: 2),
        _th('Pago',        flex: 2),
        _th('',            flex: 1),
      ]),
    );
  }

  Widget _th(String label, {required int flex}) => Expanded(
    flex: flex,
    child: Text(label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5, fontWeight: FontWeight.w600,
        color: AppColors.text2, letterSpacing: 0.4)),
  );

  Widget _tableRow(Membresia m) {
    final estado = m.estadoEfectivo;
    final dias   = m.diasRestantes;
    final porVencer = estado == 'activa' && dias <= 7;

    Color badgeColor; Color badgeBg; String badgeLabel;
    if (estado == 'activa' && !porVencer) {
      badgeColor = AppColors.success; badgeBg = const Color(0xFFDCFCE7); badgeLabel = 'Activa';
    } else if (porVencer) {
      badgeColor = AppColors.warning; badgeBg = const Color(0xFFFEF3C7); badgeLabel = 'Por vencer';
    } else if (estado == 'vencida') {
      badgeColor = AppColors.danger; badgeBg = const Color(0xFFFEE2E2); badgeLabel = 'Vencida';
    } else {
      badgeColor = AppColors.text3; badgeBg = AppColors.bg; badgeLabel = 'Suspendida';
    }

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        // Socio
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(m.nombreSocio[0],
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(m.nombreSocio,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text),
            overflow: TextOverflow.ellipsis)),
        ])),
        // Plan
        Expanded(flex: 2, child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6)),
            child: Text(m.nombrePlan,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        )),
        Expanded(flex: 2, child: _cell(fmt(m.fechaInicio))),
        Expanded(flex: 2, child: _cell(fmt(m.fechaVencimiento))),
        // Estado badge
        Expanded(flex: 2, child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(badgeLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: badgeColor)),
            ]),
          ),
        )),
        // Días restantes
        Expanded(flex: 2, child: Text(
          estado == 'vencida' ? '—' : '$dias días',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: porVencer ? AppColors.warning : (estado == 'vencida' ? AppColors.danger : AppColors.text2),
            fontWeight: porVencer ? FontWeight.w600 : FontWeight.w400),
        )),
        // Pago
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('S/. ${m.montoPagado.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          Text(m.metodoPago,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.text3)),
        ])),
        // Acción renovar
        Expanded(flex: 1, child: Tooltip(
          message: estado == 'activa'
              ? 'Disponible al vencer'
              : 'Renovar membresía',
          child: InkWell(
            onTap: () => _intentarRenovar(m),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.autorenew_rounded, size: 18,
                color: estado == 'vencida'
                    ? AppColors.danger
                    : (estado == 'activa' ? AppColors.text3 : AppColors.primary)),
            ),
          ),
        )),
      ]),
    );
  }

  Widget _cell(String text) => Text(text,
    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2));

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.card_membership, size: 40, color: AppColors.text3),
    const SizedBox(height: 10),
    Text('No se encontraron membresías',
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.text2)),
  ]));
}

// ─── Formulario (Dialog) ─────────────────────────────────────────────────────

class _MembresiaFormDialog extends StatefulWidget {
  final List<Socio> socios;
  final List<Plan>  planes;
  final Membresia?  renovando;
  final Set<int>    sociosConActiva;

  const _MembresiaFormDialog({
    required this.socios,
    required this.planes,
    required this.sociosConActiva,
    this.renovando,
  });

  @override
  State<_MembresiaFormDialog> createState() => _MembresiaFormDialogState();
}

class _MembresiaFormDialogState extends State<_MembresiaFormDialog> {
  final _formKey = GlobalKey<FormState>();

  Socio?  _socioSelected;
  Plan?   _planSelected;
  DateTime _fechaInicio = DateTime.now();
  String  _metodoPago  = 'efectivo';
  final   _obsCtrl     = TextEditingController();

  bool get _isRenovacion => widget.renovando != null;

  // true si se intenta ASIGNAR (no renovar) a un socio que ya tiene activa.
  bool get _socioYaTieneActiva =>
      !_isRenovacion &&
      _socioSelected != null &&
      widget.sociosConActiva.contains(_socioSelected!.id);

  DateTime get _fechaVencimiento => _planSelected == null
      ? _fechaInicio
      : _fechaInicio.add(Duration(days: _planSelected!.duracionDias));

  @override
  void initState() {
    super.initState();
    if (_isRenovacion) {
      final r = widget.renovando!;
      _socioSelected = widget.socios.firstWhere(
        (s) => s.id == r.idSocio,
        orElse: () => widget.socios.first,
      );
      _planSelected = widget.planes.firstWhere(
        (p) => p.id == r.idPlan,
        orElse: () => widget.planes.first,
      );
      _fechaInicio  = DateTime.now();
      _metodoPago   = r.metodoPago;
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaInicio = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Bloquea asignar una nueva membresía a un socio que ya tiene una activa.
    if (_socioYaTieneActiva) {
      setState(() {}); // refresca para mostrar la advertencia
      return;
    }

    Navigator.of(context).pop({
      'idSocio':     _socioSelected!.id,
      'idPlan':      _planSelected!.id,
      'fechaInicio': _fechaInicio,
      'metodoPago':  _metodoPago,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Encabezado
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.card_membership, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _isRenovacion ? 'Renovar membresía' : 'Asignar membresía',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
                  Text(
                    _isRenovacion
                        ? 'Se creará una nueva membresía desde hoy.'
                        : 'Selecciona el socio, el plan y registra el pago.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
                ])),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.text3)),
              ]),
              const SizedBox(height: 20),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),

              // Socio
              _label('Socio *'),
              const SizedBox(height: 5),
              DropdownButtonFormField<Socio>(
                initialValue: _socioSelected,
                isExpanded: true,
                decoration: _dropDeco(),
                hint: Text('Selecciona un socio',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3)),
                items: widget.socios.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.nombreCompleto,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text)),
                )).toList(),
                onChanged: _isRenovacion ? null : (v) => setState(() => _socioSelected = v),
                validator: (v) => v == null ? 'Selecciona un socio' : null,
              ),

              // Advertencia: el socio ya tiene una membresía activa.
              if (_socioYaTieneActiva) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Este socio ya tiene una membresía activa.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5, fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E))),
                        const SizedBox(height: 2),
                        Text(
                          'No puedes asignarle otra. Si deseas extender su plan, '
                          'usa el botón "Renovar" en la fila del socio.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5, color: const Color(0xFF92400E), height: 1.3)),
                      ],
                    )),
                  ]),
                ),
              ],
              const SizedBox(height: 14),

              // Plan
              _label('Plan de membresía *'),
              const SizedBox(height: 5),
              DropdownButtonFormField<Plan>(
                initialValue: _planSelected,
                isExpanded: true,
                decoration: _dropDeco(),
                hint: Text('Selecciona un plan',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3)),
                items: widget.planes.map((p) => DropdownMenuItem(
                  value: p,
                  child: Row(children: [
                    Expanded(child: Text(p.nombre,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text))),
                    Text('S/. ${p.precio.toStringAsFixed(0)} · ${p.duracionDias}d',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text2)),
                  ]),
                )).toList(),
                onChanged: (v) => setState(() => _planSelected = v),
                validator: (v) => v == null ? 'Selecciona un plan' : null,
              ),
              const SizedBox(height: 14),

              // Fechas
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Fecha de inicio'),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: _pickFecha,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border2)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.text3),
                        const SizedBox(width: 8),
                        Text(_fmtDate(_fechaInicio),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text)),
                      ]),
                    ),
                  ),
                ])),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Fecha de vencimiento'),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      const Icon(Icons.event_rounded, size: 15, color: AppColors.text3),
                      const SizedBox(width: 8),
                      Text(
                        _planSelected != null ? _fmtDate(_fechaVencimiento) : '—',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)),
                    ]),
                  ),
                ])),
              ]),
              const SizedBox(height: 14),

              // Método de pago + monto
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Método de pago *'),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    initialValue: _metodoPago,
                    decoration: _dropDeco(),
                    items: ['efectivo', 'transferencia'].map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m[0].toUpperCase() + m.substring(1),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text)),
                    )).toList(),
                    onChanged: (v) => setState(() => _metodoPago = v!),
                  ),
                ])),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Monto a cobrar'),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      const Icon(Icons.payments_rounded, size: 15, color: AppColors.text3),
                      const SizedBox(width: 8),
                      Text(
                        _planSelected != null
                            ? 'S/. ${_planSelected!.precio.toStringAsFixed(0)}'
                            : '—',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text)),
                    ]),
                  ),
                ])),
              ]),

              const SizedBox(height: 22),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),

              // Botones
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: AppColors.text2),
                  child: Text('Cancelar',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _socioYaTieneActiva ? null : _submit,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    _isRenovacion ? 'Confirmar renovación' : 'Asignar membresía',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border2,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text));

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  InputDecoration _dropDeco() => InputDecoration(
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
    focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
    errorBorder:    OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
  );
}
