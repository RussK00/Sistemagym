import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/reportes_service.dart';
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/core/utils/csv_util.dart';
import 'package:stanleygym_app/core/utils/descargar_archivo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _d;
  bool   _loading = true;
  String? _error;

  static const _mesesLargos = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
    'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
  static const _mesesCortos = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await ReportesService.dashboard();
      if (!mounted) return;
      setState(() { _d = d; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
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
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(),
        const SizedBox(height: 24),
        _statsGrid(),
        const SizedBox(height: 24),
        _chartCard(),
        const SizedBox(height: 24),
        _bottomRow(),
      ]),
    );
  }

  // ── Encabezado ──────────────────────────────────────────────────────────

  Widget _header() {
    final ahora = DateTime.now();
    final periodo = '${_mesesLargos[ahora.month - 1]} ${ahora.year}';
    final primerNombre = (Session.actual?.nombre ?? 'Admin').split(' ').first;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bienvenido, $primerNombre',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.8)),
        const SizedBox(height: 4),
        Text('Resumen general del gimnasio · $periodo',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.text2)),
      ])),
      OutlinedButton.icon(
        onPressed: _exportarResumen,
        icon: const Icon(Icons.file_download_outlined, size: 16, color: AppColors.text2),
        label: Text('Exportar reporte',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: AppColors.border2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ]);
  }

  // ── Exportar resumen del panel a CSV ────────────────────────────────────

  void _exportarResumen() {
    final ahora = DateTime.now();
    final asist = ((_d?['asistencia_por_mes'] as List?) ?? List.filled(12, 0))
        .map((e) => (e as num).toInt()).toList();

    // Sección 1: métricas clave
    final rows = <List<String>>[
      ['Socios activos', '${_n('socios_activos')}'],
      ['Nuevos este mes', '${_n('socios_nuevos_mes')}'],
      ['Ingresos del mes (S/.)', '${_n('ingresos_mes')}'],
      ['Ventas de suplementos (unid.)', '${_n('ventas_unidades_mes')}'],
      ['Membresías por vencer', '${_n('membresias_por_vencer')}'],
      ['', ''],
      ['Asistencia por mes ${ahora.year}', ''],
      ...List.generate(12, (i) => [_mesesLargos[i], '${asist[i]}']),
    ];

    final contenido = generarCsv(['Métrica', 'Valor'], rows);
    descargarArchivo(contenido, 'resumen_${_mesesCortos[ahora.month - 1].toLowerCase()}_${ahora.year}.csv', 'text/csv');

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Resumen exportado correctamente.',
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Tarjetas de estadísticas ────────────────────────────────────────────

  num _n(String k) => (_d?[k] as num?) ?? 0;

  Widget _statsGrid() {
    // Tendencia de ingresos vs mes anterior
    final ingMes = _n('ingresos_mes');
    final ingAnt = _n('ingresos_mes_anterior');
    final pct = ingAnt == 0 ? null : ((ingMes - ingAnt) / ingAnt * 100);
    final ventasMes = _n('ventas_unidades_mes');
    final ventasAnt = _n('ventas_unidades_mes_anterior');
    final ventasDelta = ventasMes - ventasAnt;
    final nuevos = _n('socios_nuevos_mes');

    final cards = [
      _StatCard(
        icon: Icons.people_alt_rounded, color: AppColors.primary, bgColor: const Color(0xFFEFF6FF),
        label: 'Socios Activos', value: '${_n('socios_activos')}',
        trend: '+$nuevos', trendSub: 'nuevos este mes', trendUp: true,
      ),
      _StatCard(
        icon: Icons.credit_card_rounded, color: AppColors.success, bgColor: const Color(0xFFF0FDF4),
        label: 'Ingresos del Mes', value: 'S/ ${_fmtMoneda(ingMes)}',
        trend: pct == null ? '—' : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
        trendSub: 'vs mes ant.', trendUp: (pct ?? 0) >= 0,
      ),
      _StatCard(
        icon: Icons.local_drink_rounded, color: AppColors.warning, bgColor: const Color(0xFFFFFBEB),
        label: 'Ventas Suplementos', value: '$ventasMes',
        trend: '${ventasDelta >= 0 ? '+' : ''}$ventasDelta', trendSub: 'unidades', trendUp: ventasDelta >= 0,
      ),
      _StatCard(
        icon: Icons.warning_amber_rounded, color: AppColors.danger, bgColor: const Color(0xFFFEF2F2),
        label: 'Membresías por Vencer', value: '${_n('membresias_por_vencer')}',
        trend: 'Próximos', trendSub: '${_n('dias_anticipacion')} días', trendUp: false, trendNeutral: true,
      ),
    ];

    return LayoutBuilder(builder: (context, cs) {
      final cols = cs.maxWidth > 900 ? 4 : (cs.maxWidth > 560 ? 2 : 1);
      return GridView.count(
        crossAxisCount: cols, crossAxisSpacing: 16, mainAxisSpacing: 16,
        childAspectRatio: 1.65, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), children: cards);
    });
  }

  // ── Gráfico de asistencia mensual ───────────────────────────────────────

  Widget _chartCard() {
    final datos = ((_d?['asistencia_por_mes'] as List?) ?? List.filled(12, 0))
        .map((e) => (e as num).toInt()).toList();
    final maxVal = datos.isEmpty ? 1 : (datos.reduce((a, b) => a > b ? a : b));
    final mesActual = DateTime.now().month - 1;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Asistencia mensual',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text('Visitas registradas por mes · Año ${DateTime.now().year}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${DateTime.now().year}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ]),
          ),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(12, (i) {
            final v = datos[i];
            final h = maxVal == 0 ? 0.0 : (v / maxVal);
            final esActual = i == mesActual;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (v > 0)
                  Text('$v', style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3)),
                const SizedBox(height: 4),
                Container(
                  height: (160 * h).clamp(v > 0 ? 6.0 : 0.0, 160.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: esActual
                          ? [AppColors.primaryDark, AppColors.primary]
                          : [AppColors.primary, AppColors.accentBlue]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_mesesCortos[i],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: esActual ? FontWeight.w700 : FontWeight.w500,
                    color: esActual ? AppColors.primary : AppColors.text3)),
              ]),
            ));
          })),
        ),
      ]),
    );
  }

  // ── Fila inferior: últimos socios + alertas ─────────────────────────────

  Widget _bottomRow() {
    return LayoutBuilder(builder: (context, cs) {
      if (cs.maxWidth > 800) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: _ultimosSocios()),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _alertas()),
        ]);
      }
      return Column(children: [_ultimosSocios(), const SizedBox(height: 16), _alertas()]);
    });
  }

  Widget _ultimosSocios() {
    final socios = (_d?['ultimos_socios'] as List?) ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Últimos socios registrados',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
        const SizedBox(height: 16),
        // Cabecera
        Row(children: [
          _th('SOCIO', flex: 4), _th('PLAN', flex: 2), _th('ESTADO', flex: 2), _th('REGISTRADO', flex: 2),
        ]),
        const Divider(height: 20, color: AppColors.border),
        if (socios.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Aún no hay socios registrados.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)))
        else
          ...socios.map((s) => _socioRow(s as Map<String, dynamic>)),
      ]),
    );
  }

  Widget _socioRow(Map<String, dynamic> s) {
    final nombre = s['nombre'] as String? ?? '';
    final plan   = s['plan'] as String? ?? '—';
    final activo = (s['estado'] as String?) == 'activo';
    final fecha  = _fmtFechaCorta(s['fecha_registro'] as String?);
    final iniciales = nombre.trim().isEmpty ? '?'
        : nombre.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Expanded(flex: 4, child: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: const Color(0xFFF1F5F9),
            child: Text(iniciales, style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2))),
          const SizedBox(width: 10),
          Flexible(child: Text(nombre,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
            overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 2, child: Text(plan,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: activo ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(
                color: activo ? AppColors.success : AppColors.text3, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(activo ? 'Activo' : 'Inactivo', style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5, fontWeight: FontWeight.w600,
                color: activo ? AppColors.success : AppColors.text2)),
            ]),
          ),
        )),
        Expanded(flex: 2, child: Text(fecha,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2))),
      ]),
    );
  }

  Widget _alertas() {
    final porVencer = _n('membresias_por_vencer').toInt();
    final dias = _n('dias_anticipacion').toInt();
    final stockBajo = (_d?['stock_bajo'] as List?) ?? [];

    final alertas = <Widget>[];
    if (porVencer > 0) {
      alertas.add(_alerta(
        const Color(0xFFFEF3C7), const Color(0xFFFDE68A), const Color(0xFFD97706),
        '$porVencer membresía${porVencer != 1 ? 's' : ''} por vencer',
        'Próximos $dias días — revisa Reportes'));
    }
    for (final p in stockBajo) {
      final m = p as Map<String, dynamic>;
      alertas.add(_alerta(
        const Color(0xFFFEF2F2), const Color(0xFFFECACA), AppColors.danger,
        'Stock bajo: ${m['nombre']}',
        'Quedan ${m['stock']} unidades'));
    }
    if (alertas.isEmpty) {
      alertas.add(_alerta(
        const Color(0xFFF0FDF4), const Color(0xFFBBF7D0), AppColors.success,
        'Todo en orden',
        'No hay alertas por ahora'));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Alertas',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
        const SizedBox(height: 16),
        ...alertas.map((a) => Padding(padding: const EdgeInsets.only(bottom: 10), child: a)),
      ]),
    );
  }

  Widget _alerta(Color bg, Color border, Color iconColor, String titulo, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
          child: Icon(Icons.notifications_rounded, size: 18, color: iconColor)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text2)),
        ])),
      ]),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
  );

  Widget _th(String t, {required int flex}) => Expanded(flex: flex,
    child: Text(t, style: GoogleFonts.plusJakartaSans(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 0.5)));

  String _fmtMoneda(num n) {
    final s = n.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _fmtFechaCorta(String? iso) {
    if (iso == null) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return '—';
    final hoy = DateTime.now();
    if (d.year == hoy.year && d.month == hoy.month && d.day == hoy.day) return 'Hoy';
    return '${d.day} ${_mesesCortos[d.month - 1]}';
  }
}

// ─── StatCard ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final Color    bgColor;
  final String   trend;
  final String   trendSub;
  final bool     trendUp;
  final bool     trendNeutral;

  const _StatCard({
    required this.icon, required this.label, required this.value,
    required this.color, required this.bgColor,
    required this.trend, required this.trendSub, required this.trendUp,
    this.trendNeutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = trendNeutral ? AppColors.danger : (trendUp ? AppColors.success : AppColors.danger);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text2))),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 18)),
        ]),
        const SizedBox(height: 10),
        Text(value,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -1, height: 1)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(
            trendNeutral ? Icons.arrow_downward_rounded : (trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
            size: 13, color: trendColor),
          const SizedBox(width: 2),
          Text(trend, style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5, fontWeight: FontWeight.w700, color: trendColor)),
          const SizedBox(width: 5),
          Flexible(child: Text(trendSub,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.text3),
            overflow: TextOverflow.ellipsis)),
        ]),
      ]),
    );
  }
}
