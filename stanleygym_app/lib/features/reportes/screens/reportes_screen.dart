import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/reportes_service.dart';
import 'package:stanleygym_app/core/api/socios_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/core/utils/csv_util.dart';
import 'package:stanleygym_app/core/utils/descargar_archivo.dart';
import 'package:stanleygym_app/features/asistencia/models/asistencia.dart';
import 'package:stanleygym_app/features/membresias/models/membresia.dart';

const _meses = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
                 'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];

// ─── ReportesScreen ──────────────────────────────────────────────────────────

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  int _mesSeleccionado = DateTime.now().month; // 1-12
  final int _anio = DateTime.now().year;
  int _tab = 0; // 0: asistencia | 1: membresías

  List<Asistencia> _asistencia = [];
  List<Membresia>  _membresias = [];
  int  _totalSocios = 0;
  bool _loadingAsist = true;
  bool _loadingMem   = true;
  String? _errorAsist;
  String? _errorMem;

  @override
  void initState() {
    super.initState();
    _cargarAsistencia();
    _cargarMembresias();
  }

  Future<void> _cargarAsistencia() async {
    setState(() { _loadingAsist = true; _errorAsist = null; });
    try {
      final lista = await ReportesService.asistenciaMensual(_mesSeleccionado, _anio);
      if (!mounted) return;
      setState(() { _asistencia = lista; _loadingAsist = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorAsist = e.toString(); _loadingAsist = false; });
    }
  }

  Future<void> _cargarMembresias() async {
    setState(() { _loadingMem = true; _errorMem = null; });
    try {
      final results = await Future.wait([
        ReportesService.estadoMembresias(),
        SociosService.listar(),
      ]);
      if (!mounted) return;
      setState(() {
        _membresias  = results[0] as List<Membresia>;
        _totalSocios = (results[1] as List).length;
        _loadingMem  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMem = e.toString(); _loadingMem = false; });
    }
  }

  List<Asistencia> get _asistenciaFiltrada => _asistencia;

  List<_SocioResumen> get _resumenPorSocio {
    final map = <int, _SocioResumen>{};
    for (final a in _asistenciaFiltrada) {
      map.update(
        a.idSocio,
        (r) => _SocioResumen(
          idSocio:     r.idSocio,
          nombre:      r.nombre,
          plan:        r.plan,
          totalVisitas: r.totalVisitas + 1,
          ultimaVisita: a.fechaHoraIngreso.isAfter(r.ultimaVisita)
              ? a.fechaHoraIngreso : r.ultimaVisita,
        ),
        ifAbsent: () => _SocioResumen(
          idSocio:     a.idSocio,
          nombre:      a.nombreSocio,
          plan:        a.planSocio,
          totalVisitas: 1,
          ultimaVisita: a.fechaHoraIngreso,
        ),
      );
    }
    final list = map.values.toList();
    list.sort((a, b) => b.totalVisitas.compareTo(a.totalVisitas));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(),
        const SizedBox(height: 20),
        _tabs(),
        const SizedBox(height: 20),
        Expanded(child: _tab == 0 ? _vistaAsistencia() : _vistaMembresias()),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header() {
    return Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Reportes',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppColors.text, letterSpacing: -0.4)),
        Text('Consulta estadísticas de asistencia y estado de membresías.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
      ]),
      const Spacer(),
      // Selector de mes
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border2),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _mesSeleccionado,
            isDense: true,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text, fontWeight: FontWeight.w500),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.text2),
            items: List.generate(12, (i) => DropdownMenuItem(
              value: i + 1,
              child: Text(_meses[i]),
            )),
            onChanged: (v) {
              setState(() => _mesSeleccionado = v!);
              _cargarAsistencia();
            },
          ),
        ),
      ),
      const SizedBox(width: 10),
      // Botón exportar CSV
      FilledButton.icon(
        onPressed: _exportar,
        icon: const Icon(Icons.file_download_outlined, size: 16),
        label: Text('Exportar CSV',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ]);
  }

  // ── Exportar a CSV ──────────────────────────────────────────────────────────

  void _exportar() {
    String contenido;
    String nombre;

    if (_tab == 0) {
      // Asistencia del mes
      final filas = _asistencia.map((a) => [
        a.nombreSocio,
        a.planSocio,
        _fmtFecha(a.fechaHoraIngreso),
        _fmtHora(a.fechaHoraIngreso),
      ]).toList();
      contenido = generarCsv(['Socio', 'Plan', 'Fecha', 'Hora'], filas);
      nombre = 'asistencia_${_meses[_mesSeleccionado - 1].toLowerCase()}_$_anio.csv';
    } else {
      // Estado de membresías
      final filas = _membresias.map((m) => [
        m.nombreSocio,
        m.nombrePlan,
        _fmtFecha(m.fechaInicio),
        _fmtFecha(m.fechaVencimiento),
        m.estadoEfectivo,
        m.estadoEfectivo == 'vencida' ? '0' : '${m.diasRestantes}',
      ]).toList();
      contenido = generarCsv(
        ['Socio', 'Plan', 'Inicio', 'Vencimiento', 'Estado', 'Días restantes'], filas);
      nombre = 'membresias_$_anio.csv';
    }

    if (contenido.split('\n').length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No hay datos para exportar.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    descargarArchivo(contenido, nombre, 'text/csv');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Reporte exportado: $nombre',
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Tabs ─────────────────────────────────────────────────────────────────

  Widget _tabs() {
    return Row(children: [
      _tabBtn(0, Icons.bar_chart_rounded,    'Asistencia mensual'),
      const SizedBox(width: 8),
      _tabBtn(1, Icons.card_membership,      'Estado de membresías'),
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
          color:        active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: active ? AppColors.primary : AppColors.border2),
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

  Widget _errorView(String mensaje, VoidCallback onRetry) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.text3),
      const SizedBox(height: 10),
      Text(mensaje, textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: Text('Reintentar', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
      ),
    ]));
  }

  // ── Vista: Asistencia mensual ─────────────────────────────────────────────

  Widget _vistaAsistencia() {
    if (_loadingAsist) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_errorAsist != null) {
      return _errorView(_errorAsist!, _cargarAsistencia);
    }
    final asistencia = _asistenciaFiltrada;
    final resumen    = _resumenPorSocio;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Tarjetas resumen
      Row(children: [
        _miniCard('Total ingresos', '${asistencia.length}',
          Icons.how_to_reg_rounded, AppColors.primary, const Color(0xFFEFF6FF)),
        const SizedBox(width: 16),
        _miniCard('Socios distintos', '${resumen.length}',
          Icons.people_alt_rounded, AppColors.success, const Color(0xFFF0FDF4)),
        const SizedBox(width: 16),
        _miniCard('Promedio por socio',
          resumen.isEmpty ? '—' : (asistencia.length / resumen.length).toStringAsFixed(1),
          Icons.trending_up_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
      ]),
      const SizedBox(height: 20),

      // Tabla de ingresos detallada
      Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Tabla detalle
        Expanded(flex: 3, child: _tablaAsistencia(asistencia)),
        const SizedBox(width: 16),
        // Ranking por socio
        Expanded(flex: 2, child: _rankingSocios(resumen)),
      ])),
    ]);
  }

  Widget _miniCard(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0,2))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.5)),
          Text(label,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text2)),
        ]),
      ]),
    ));
  }

  Widget _tablaAsistencia(List<Asistencia> rows) {
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
          // Header
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              _th('Socio',  flex: 3),
              _th('Plan',   flex: 2),
              _th('Fecha',  flex: 2),
              _th('Hora',   flex: 2),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: rows.isEmpty
                ? Center(child: Text('Sin registros para ${_meses[_mesSeleccionado-1]}.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)))
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, i) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final a = rows[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(children: [
                          Expanded(flex: 3, child: Row(children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              child: Text(a.nombreSocio[0],
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
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
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                              child: Text(a.planSocio,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ),
                          )),
                          Expanded(flex: 2, child: Text(_fmtFecha(a.fechaHoraIngreso),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2))),
                          Expanded(flex: 2, child: Text(_fmtHora(a.fechaHoraIngreso),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text))),
                        ]),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _rankingSocios(List<_SocioResumen> resumen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text('Asistencia por socio',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 0.4)),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: resumen.isEmpty
                ? Center(child: Text('Sin datos.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: resumen.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final r = resumen[i];
                      final maxVisitas = resumen.first.totalVisitas;
                      final pct = r.totalVisitas / maxVisitas;
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Text(r.nombre[0],
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r.nombre,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.text),
                            overflow: TextOverflow.ellipsis)),
                          Text('${r.totalVisitas} visita${r.totalVisitas != 1 ? 's' : ''}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ]),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFEFF6FF),
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ]);
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  // ── Vista: Estado de membresías ───────────────────────────────────────────

  Widget _vistaMembresias() {
    if (_loadingMem) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_errorMem != null) {
      return _errorView(_errorMem!, _cargarMembresias);
    }
    final activas   = _membresias.where((m) => m.estadoEfectivo == 'activa' && m.diasRestantes > 7).length;
    final porVencer = _membresias.where((m) => m.estadoEfectivo == 'activa' && m.diasRestantes <= 7).length;
    final vencidas  = _membresias.where((m) => m.estadoEfectivo == 'vencida').length;
    final total     = _totalSocios;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Tarjetas resumen
      Row(children: [
        _miniCard('Total socios',       '$total',      Icons.people_alt_rounded,   AppColors.text2,          const Color(0xFFF1F5F9)),
        const SizedBox(width: 16),
        _miniCard('Activas',            '$activas',    Icons.check_circle_rounded,  AppColors.success,        const Color(0xFFF0FDF4)),
        const SizedBox(width: 16),
        _miniCard('Por vencer (≤7d)',   '$porVencer',  Icons.warning_amber_rounded, AppColors.warning,        const Color(0xFFFFFBEB)),
        const SizedBox(width: 16),
        _miniCard('Vencidas',           '$vencidas',   Icons.cancel_rounded,        AppColors.danger,         const Color(0xFFFEF2F2)),
      ]),
      const SizedBox(height: 20),
      Expanded(child: _tablaMembresias()),
    ]);
  }

  Widget _tablaMembresias() {
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
              _th('Socio',        flex: 3),
              _th('Plan',         flex: 2),
              _th('Vencimiento',  flex: 2),
              _th('Días rest.',   flex: 2),
              _th('Estado',       flex: 2),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.separated(
              itemCount: _membresias.length,
              separatorBuilder: (_, i) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) {
                final m      = _membresias[i];
                final estado = m.estadoEfectivo;
                final porVencer = estado == 'activa' && m.diasRestantes <= 7;

                Color bColor; Color bBg; String bLabel;
                if (estado == 'activa' && !porVencer) {
                  bColor = AppColors.success; bBg = const Color(0xFFDCFCE7); bLabel = 'Activa';
                } else if (porVencer) {
                  bColor = AppColors.warning; bBg = const Color(0xFFFEF3C7); bLabel = 'Por vencer';
                } else {
                  bColor = AppColors.danger; bBg = const Color(0xFFFEE2E2); bLabel = 'Vencida';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Expanded(flex: 3, child: Row(children: [
                      CircleAvatar(
                        radius: 14,
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
                    Expanded(flex: 2, child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                        child: Text(m.nombrePlan,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ),
                    )),
                    Expanded(flex: 2, child: Text(_fmtFecha(m.fechaVencimiento),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2))),
                    Expanded(flex: 2, child: Text(
                      estado == 'vencida' ? '—' : '${m.diasRestantes}d',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: porVencer ? FontWeight.w600 : FontWeight.w400,
                        color: porVencer ? AppColors.warning : (estado == 'vencida' ? AppColors.danger : AppColors.text2)))),
                    Expanded(flex: 2, child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: bBg, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 6, height: 6,
                            decoration: BoxDecoration(color: bColor, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(bLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5, fontWeight: FontWeight.w600, color: bColor)),
                        ]),
                      ),
                    )),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _th(String label, {required int flex}) => Expanded(
    flex: flex,
    child: Text(label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 0.4)),
  );

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  String _fmtHora(DateTime d) =>
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

class _SocioResumen {
  final int      idSocio;
  final String   nombre;
  final String   plan;
  final int      totalVisitas;
  final DateTime ultimaVisita;

  const _SocioResumen({
    required this.idSocio,
    required this.nombre,
    required this.plan,
    required this.totalVisitas,
    required this.ultimaVisita,
  });
}
