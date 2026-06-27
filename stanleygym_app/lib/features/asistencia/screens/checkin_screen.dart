import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/asistencia_service.dart';
import 'package:stanleygym_app/core/api/membresias_service.dart';
import 'package:stanleygym_app/core/api/socios_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/asistencia/models/asistencia.dart';
import 'package:stanleygym_app/features/membresias/models/membresia.dart';
import 'package:stanleygym_app/features/socios/models/socio.dart';

// ─── CheckinScreen ───────────────────────────────────────────────────────────

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final _searchCtrl = TextEditingController();

  // Datos cargados del backend
  List<Asistencia> _ingresos   = [];
  List<Socio>      _socios      = [];
  List<Membresia>  _membresias  = [];
  bool   _loading = true;
  String? _error;
  bool   _registrando = false;

  // Socio encontrado en la búsqueda
  Socio?     _socioEncontrado;
  Membresia? _membresiaActual;
  bool       _buscado = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        AsistenciaService.ingresosHoy(),
        SociosService.listar(),
        MembresiasService.listar(),
      ]);
      if (!mounted) return;
      setState(() {
        _ingresos   = results[0] as List<Asistencia>;
        _socios     = results[1] as List<Socio>;
        _membresias = results[2] as List<Membresia>;
        _loading    = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _buscar(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() { _socioEncontrado = null; _membresiaActual = null; _buscado = false; });
      return;
    }

    final socio = _socios.cast<Socio?>().firstWhere(
      (s) => s!.nombreCompleto.toLowerCase().contains(q) || s.dni.contains(q),
      orElse: () => null,
    );

    Membresia? mem;
    if (socio != null) {
      mem = _membresias.cast<Membresia?>().firstWhere(
        (m) => m!.idSocio == socio.id,
        orElse: () => null,
      );
    }

    setState(() {
      _socioEncontrado = socio;
      _membresiaActual = mem;
      _buscado         = true;
    });
  }

  void _registrarIngreso() async {
    final socio = _socioEncontrado!;
    setState(() => _registrando = true);
    try {
      await AsistenciaService.registrar(socio.id);
      // Recargar ingresos del día desde el backend
      final lista = await AsistenciaService.ingresosHoy();
      if (!mounted) return;
      setState(() {
        _ingresos = lista;
        _registrando = false;
        _searchCtrl.clear();
        _socioEncontrado = null;
        _membresiaActual = null;
        _buscado = false;
      });
      _showSnack('Ingreso de ${socio.nombres} registrado correctamente.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _registrando = false);
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
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
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel izquierdo — búsqueda y confirmación
          SizedBox(width: 340, child: _leftPanel()),
          const SizedBox(width: 24),
          // Panel derecho — registro del día
          Expanded(child: _rightPanel()),
        ],
      ),
    );
  }

  // ── Panel izquierdo ──────────────────────────────────────────────────────

  Widget _leftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Registrar ingreso', Icons.how_to_reg_rounded),
        const SizedBox(height: 16),
        _searchField(),
        const SizedBox(height: 16),
        if (_buscado) _resultCard(),
      ],
    );
  }

  Widget _searchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Buscar socio',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text)),
        const SizedBox(height: 6),
        TextField(
          controller: _searchCtrl,
          onChanged:  _buscar,
          onSubmitted: _buscar,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
          decoration: InputDecoration(
            hintText:  'Nombre o DNI del socio…',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3),
            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.text3),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.text3),
                    onPressed: () {
                      _searchCtrl.clear();
                      _buscar('');
                    },
                  )
                : null,
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border2)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 8),
        Text('Escribe el nombre completo o los 8 dígitos del DNI.',
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.text3)),
      ],
    );
  }

  Widget _resultCard() {
    // Socio no encontrado
    if (_socioEncontrado == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(children: [
          const Icon(Icons.person_off_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('No se encontró ningún socio con ese nombre o DNI.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.danger))),
        ]),
      );
    }

    final socio   = _socioEncontrado!;
    final mem     = _membresiaActual;
    final estado  = mem?.estadoEfectivo ?? 'sin membresía';
    final activo  = estado == 'activa';
    final porVencer = activo && (mem?.diasRestantes ?? 99) <= 7;
    final socioInactivo = socio.estado != 'activo';

    // Color y mensaje de estado
    Color cardBorder; Color cardBg; Color estadoColor; String estadoLabel; IconData estadoIcon;
    if (activo && !porVencer) {
      cardBorder = const Color(0xFFBBF7D0); cardBg = const Color(0xFFF0FDF4);
      estadoColor = AppColors.success; estadoLabel = 'Membresía activa'; estadoIcon = Icons.check_circle_rounded;
    } else if (porVencer) {
      cardBorder = const Color(0xFFFDE68A); cardBg = const Color(0xFFFFFBEB);
      estadoColor = AppColors.warning; estadoLabel = 'Por vencer (${mem!.diasRestantes}d)'; estadoIcon = Icons.warning_amber_rounded;
    } else {
      cardBorder = const Color(0xFFFECACA); cardBg = const Color(0xFFFEF2F2);
      estadoColor = AppColors.danger;
      estadoLabel = estado == 'sin membresía' ? 'Sin membresía' : 'Membresía vencida';
      estadoIcon = Icons.cancel_rounded;
    }

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cabecera socio
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(socio.nombres[0],
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(socio.nombreCompleto,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.2)),
              Text('DNI: ${socio.dni}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text2)),
            ])),
          ]),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 10),

          // Estado membresía
          Row(children: [
            Icon(estadoIcon, size: 15, color: estadoColor),
            const SizedBox(width: 6),
            Text(estadoLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: estadoColor)),
          ]),

          if (mem != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.card_membership, size: 13, color: AppColors.text3),
              const SizedBox(width: 5),
              Text('Plan ${mem.nombrePlan}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
              const Spacer(),
              Text('Vence: ${_fmtDate(mem.fechaVencimiento)}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text3)),
            ]),
          ],

          // Alerta: socio inactivo (dado de baja) — tiene prioridad
          if (socioInactivo) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.person_off_rounded, size: 15, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  'Este socio está inactivo (dado de baja). Actívalo en la sección Socios para permitir su ingreso.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.danger, height: 1.4))),
              ]),
            ),
          ],

          // Alerta si no puede ingresar por la membresía
          if (!activo && !socioInactivo) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7)),
              child: Text(
                estado == 'sin membresía'
                    ? 'Este socio no tiene una membresía asignada. Dirígete a Membresías para asignar una.'
                    : 'La membresía de este socio está vencida. Renuévala antes de registrar el ingreso.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.danger, height: 1.4)),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 14),

      // Botón registrar
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: (activo && !socioInactivo && !_registrando) ? _registrarIngreso : null,
          icon: _registrando
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.how_to_reg_rounded, size: 18),
          label: Text(_registrando ? 'Registrando…' : 'Confirmar ingreso',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            disabledBackgroundColor: AppColors.border,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    ]);
  }

  // ── Panel derecho — registro del día ─────────────────────────────────────

  Widget _rightPanel() {
    final hoy     = DateTime.now();
    final ingresosHoy = _ingresos.where((a) =>
      a.fechaHoraIngreso.day   == hoy.day &&
      a.fechaHoraIngreso.month == hoy.month &&
      a.fechaHoraIngreso.year  == hoy.year,
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _sectionTitle('Ingresos de hoy', Icons.list_alt_rounded),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20)),
            child: Text('${ingresosHoy.length} registrado${ingresosHoy.length != 1 ? 's' : ''}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(children: [
                _logHeader(),
                const Divider(height: 1, color: AppColors.border),
                Expanded(
                  child: ingresosHoy.isEmpty
                      ? _emptyLog()
                      : ListView.separated(
                          itemCount: ingresosHoy.length,
                          separatorBuilder: (_, i) => const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (_, i) => _logRow(ingresosHoy[i], i + 1),
                        ),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _logHeader() {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        _th('#',      flex: 1),
        _th('Socio',  flex: 4),
        _th('Plan',   flex: 2),
        _th('Hora de ingreso', flex: 3),
      ]),
    );
  }

  Widget _logRow(Asistencia a, int num) {
    final hora = '${a.fechaHoraIngreso.hour.toString().padLeft(2,'0')}:'
                 '${a.fechaHoraIngreso.minute.toString().padLeft(2,'0')}:'
                 '${a.fechaHoraIngreso.second.toString().padLeft(2,'0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(flex: 1, child: Text('$num',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text3))),
        Expanded(flex: 4, child: Row(children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.success.withValues(alpha: 0.12),
            child: Text(a.nombreSocio[0],
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(a.nombreSocio,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text),
            overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 2, child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
            child: Text(a.planSocio,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        )),
        Expanded(flex: 3, child: Row(children: [
          const Icon(Icons.access_time_rounded, size: 13, color: AppColors.text3),
          const SizedBox(width: 5),
          Text(hora,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text,
              fontFeatures: [const FontFeature.tabularFigures()])),
        ])),
      ]),
    );
  }

  Widget _emptyLog() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.inbox_rounded, size: 40, color: AppColors.text3),
      const SizedBox(height: 10),
      Text('Sin ingresos registrados hoy',
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.text2)),
      const SizedBox(height: 4),
      Text('Los check-ins aparecerán aquí en tiempo real.',
        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text3)),
    ]));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionTitle(String label, IconData icon) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(label,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
    ]);
  }

  Widget _th(String label, {required int flex}) => Expanded(
    flex: flex,
    child: Text(label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 0.4)),
  );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}
