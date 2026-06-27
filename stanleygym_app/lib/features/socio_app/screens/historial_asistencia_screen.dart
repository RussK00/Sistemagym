import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/socio_service.dart';
import 'package:stanleygym_app/core/auth/usuario_rol.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/asistencia/models/asistencia.dart';

class HistorialAsistenciaScreen extends StatefulWidget {
  final UsuarioSesion usuario;
  const HistorialAsistenciaScreen({super.key, required this.usuario});

  @override
  State<HistorialAsistenciaScreen> createState() =>
      _HistorialAsistenciaScreenState();
}

class _HistorialAsistenciaScreenState
    extends State<HistorialAsistenciaScreen> {
  List<Asistencia> _todas = [];
  bool _loading = true;
  String? _error;

  static const _diasSem = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _mesesNombre = [
    'Enero','Febrero','Marzo','Abril','Mayo','Junio',
    'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre',
  ];
  static const _mesesCorto = [
    'Ene','Feb','Mar','Abr','May','Jun',
    'Jul','Ago','Sep','Oct','Nov','Dic',
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await SocioService.miAsistencia();
      if (!mounted) return;
      setState(() { _todas = lista; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ─── Cálculos ─────────────────────────────────────────────────────────────

  int get _visitasMes {
    final now = DateTime.now();
    return _todas
        .where((a) =>
            a.fechaHoraIngreso.month == now.month &&
            a.fechaHoraIngreso.year == now.year)
        .length;
  }

  int get _racha {
    if (_todas.isEmpty) return 0;
    final fechas = _todas
        .map((a) => DateTime(
            a.fechaHoraIngreso.year,
            a.fechaHoraIngreso.month,
            a.fechaHoraIngreso.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final hoy   = DateTime.now();
    final hoySolo = DateTime(hoy.year, hoy.month, hoy.day);
    final ayer    = hoySolo.subtract(const Duration(days: 1));

    if (fechas.first != hoySolo && fechas.first != ayer) return 0;

    int racha = 1;
    for (int i = 0; i < fechas.length - 1; i++) {
      if (fechas[i].difference(fechas[i + 1]).inDays == 1) {
        racha++;
      } else {
        break;
      }
    }
    return racha;
  }

  Set<int> get _diasAsistidosMes {
    final now = DateTime.now();
    return _todas
        .where((a) =>
            a.fechaHoraIngreso.month == now.month &&
            a.fechaHoraIngreso.year == now.year)
        .map((a) => a.fechaHoraIngreso.day)
        .toSet();
  }

  List<Asistencia> get _recientes {
    return (List<Asistencia>.of(_todas)
          ..sort((a, b) =>
              b.fechaHoraIngreso.compareTo(a.fechaHoraIngreso)))
        .take(15)
        .toList();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.text3),
            const SizedBox(height: 10),
            Text(_error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5, color: AppColors.text2)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Reintentar',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ]),
        ),
      );
    }

    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text('Mi Asistencia',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 24, fontWeight: FontWeight.w800,
              color: AppColors.text, letterSpacing: -0.5)),
          const SizedBox(height: 18),

          // Banner resumen del mes
          _bannerMes(now),
          const SizedBox(height: 16),

          // Mini calendario
          _calendarioCard(now),
          const SizedBox(height: 16),

          // Asistencias recientes
          _recientesCard(),
        ],
      ),
    );
  }

  // ─── Banner del mes ───────────────────────────────────────────────────────

  Widget _bannerMes(DateTime now) {
    final visitas = _visitasMes;
    final racha   = _racha;
    final mes     = '${_mesesNombre[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Brillo radial
          Positioned(
            top: -40, right: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Número grande + subtítulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$visitas',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 52, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: -2, height: 1)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            visitas == 1 ? 'visita' : 'visitas',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'este mes · $mes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              // Chip de racha
              if (racha > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 22)),
                      const SizedBox(height: 2),
                      Text('Racha $racha',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Mini calendario ──────────────────────────────────────────────────────

  Widget _calendarioCard(DateTime now) {
    final diasAsistidos = _diasAsistidosMes;
    final diasEnMes = DateTime(now.year, now.month + 1, 0).day;
    // weekday del primer día: 1=Lun, 7=Dom → offset 0–6
    final offset = DateTime(now.year, now.month, 1).weekday - 1;
    final mes = '${_mesesNombre[now.month - 1]} ${now.year}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado + leyenda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(mes,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.text, letterSpacing: -0.3)),
              Row(children: [
                _leyendaDot(AppColors.primary, 'Asistió'),
                const SizedBox(width: 10),
                _leyendaDot(AppColors.navyDeep, 'Hoy'),
              ]),
            ],
          ),
          const SizedBox(height: 14),

          // Cabecera días de semana
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _diasSem
                .map((d) => Center(
                      child: Text(d,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5, fontWeight: FontWeight.w700,
                          color: AppColors.text3)),
                    ))
                .toList(),
          ),

          // Celdas del mes
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Offset del primer día
              ...List.generate(offset, (_) => const SizedBox()),
              // Días del mes
              ...List.generate(diasEnMes, (i) {
                final dia = i + 1;
                final esHoy   = dia == now.day;
                final asistio = diasAsistidos.contains(dia);
                return _diaCell(dia, esHoy, asistio);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leyendaDot(Color color, String label) {
    return Row(children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11, color: AppColors.text2)),
    ]);
  }

  Widget _diaCell(int dia, bool esHoy, bool asistio) {
    Color? bg;
    Color textColor = AppColors.text2;
    List<BoxShadow>? shadows;
    FontWeight fw = FontWeight.w500;

    if (esHoy) {
      bg = AppColors.navyDeep;
      textColor = Colors.white;
      fw = FontWeight.w700;
    } else if (asistio) {
      bg = AppColors.primary;
      textColor = Colors.white;
      fw = FontWeight.w700;
      shadows = [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.4),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }

    return Center(
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: shadows,
        ),
        child: Center(
          child: Text('$dia',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: fw, color: textColor)),
        ),
      ),
    );
  }

  // ─── Asistencias recientes ────────────────────────────────────────────────

  Widget _recientesCard() {
    final lista = _recientes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Asistencias recientes',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.text, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        if (lista.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              const Icon(Icons.event_busy_rounded,
                  size: 36, color: AppColors.text3),
              const SizedBox(height: 8),
              Text('Sin registros de asistencia',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, color: AppColors.text2)),
            ]),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(lista.length, (i) {
                final last = i == lista.length - 1;
                return Column(children: [
                  _asistenciaTile(lista[i]),
                  if (!last)
                    const Divider(
                      height: 1, color: AppColors.border,
                      indent: 16, endIndent: 16),
                ]);
              }),
            ),
          ),
      ],
    );
  }

  Widget _asistenciaTile(Asistencia a) {
    final f    = a.fechaHoraIngreso;
    final hora = '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
    final now  = DateTime.now();
    final esHoy = f.year == now.year &&
        f.month == now.month &&
        f.day == now.day;
    final esAyer = f.year == now.year &&
        f.month == now.month &&
        f.day == now.day - 1;

    String etiqueta;
    if (esHoy) {
      etiqueta = 'Hoy';
    } else if (esAyer) {
      etiqueta = 'Ayer';
    } else {
      etiqueta = '${f.day} ${_mesesCorto[f.month - 1]}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Check verde
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
        ),
        const SizedBox(width: 12),
        // Fecha + subtítulo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w600,
                  color: AppColors.text)),
              Text('Ingreso registrado',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5, color: AppColors.text3)),
            ],
          ),
        ),
        // Hora
        Row(children: [
          const Icon(Icons.access_time_rounded,
              size: 13, color: AppColors.text3),
          const SizedBox(width: 4),
          Text(hora,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2)),
        ]),
      ]),
    );
  }
}
