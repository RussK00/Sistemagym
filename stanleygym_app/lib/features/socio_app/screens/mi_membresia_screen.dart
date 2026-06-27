import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/socio_service.dart';
import 'package:stanleygym_app/core/auth/usuario_rol.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/membresias/models/membresia.dart';
import 'package:stanleygym_app/features/socio_app/screens/notificaciones_screen.dart';

class MiMembresiaScreen extends StatefulWidget {
  final UsuarioSesion usuario;
  final VoidCallback onLogout;
  const MiMembresiaScreen({
    super.key,
    required this.usuario,
    required this.onLogout,
  });

  @override
  State<MiMembresiaScreen> createState() => _MiMembresiaScreenState();
}

class _MiMembresiaScreenState extends State<MiMembresiaScreen> {
  Membresia? _membresia;
  int _noLeidas = 0;
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
      final mem = await SocioService.miMembresia();
      if (!mounted) return;
      setState(() { _membresia = mem; _loading = false; });
      _cargarNotificaciones();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _cargarNotificaciones() async {
    try {
      final lista = await SocioService.misNotificaciones();
      if (!mounted) return;
      setState(() => _noLeidas = lista.where((n) => !n.leida).length);
    } catch (_) {}
  }

  Future<void> _abrirNotificaciones() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
    );
    _cargarNotificaciones();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Reintentar',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ]),
        ),
      );
    }

    final mem = _membresia;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(),
          const SizedBox(height: 20),
          Text(
            'Membresía',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 24, fontWeight: FontWeight.w800,
              color: AppColors.text, letterSpacing: -0.5),
          ),
          const SizedBox(height: 18),
          if (mem == null)
            _sinMembresia()
          else ...[
            _premiumCard(mem),
            if (mem.diasRestantes <= 5 && mem.estadoEfectivo == 'activa') ...[
              const SizedBox(height: 14),
              _alertaBanner(mem.diasRestantes),
            ],
            const SizedBox(height: 16),
            _progressCard(mem),
            const SizedBox(height: 16),
            _beneficiosCard(),
          ],
        ],
      ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: Center(
            child: Text('SG',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 10),
        Text('StalinProGym',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: AppColors.text, letterSpacing: -0.3)),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: _abrirNotificaciones,
              icon: const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.text2),
            ),
            if (_noLeidas > 0)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        IconButton(
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.text2),
          tooltip: 'Cerrar sesión',
        ),
      ],
    );
  }

  // ─── Tarjeta premium ──────────────────────────────────────────────────────

  Widget _premiumCard(Membresia m) {
    final vencida = m.estadoEfectivo == 'vencida';
    final List<Color> gradient = vencida
        ? [const Color(0xFF991B1B), const Color(0xFF7F1D1D)]
        : [AppColors.primary, AppColors.primaryDark];
    final Color shadow = vencida
        ? AppColors.danger.withValues(alpha: 0.35)
        : AppColors.primary.withValues(alpha: 0.35);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 32, offset: const Offset(0, 14)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Sheen superior-derecha
            Positioned(
              top: -50, right: -50,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Sheen inferior-izquierda
            Positioned(
              bottom: -55, left: -35,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withValues(alpha: 0.11),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila logo + badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('SG',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('StalinProGym',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9))),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          vencida ? 'VENCIDA' : 'ACTIVA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.w800,
                            color: vencida ? AppColors.danger : AppColors.primary,
                            letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Plan
                  Text('Plan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
                  const SizedBox(height: 2),
                  Text(m.nombrePlan,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 34, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: -1.2, height: 1)),
                  const SizedBox(height: 22),

                  // Divisor
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),

                  // Fechas
                  Row(children: [
                    Expanded(child: _fechaCol('INICIO', m.fechaInicio)),
                    Container(
                      width: 1, height: 36,
                      color: Colors.white.withValues(alpha: 0.25),
                      margin: const EdgeInsets.only(right: 16),
                    ),
                    Expanded(child: _fechaCol('VENCE', m.fechaVencimiento)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fechaCol(String label, DateTime fecha) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.6), letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(_fmtFecha(fecha),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  // ─── Banner de alerta ─────────────────────────────────────────────────────

  Widget _alertaBanner(int dias) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.access_time_rounded,
            color: Color(0xFFD97706), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Tu membresía vence en $dias ${dias == 1 ? 'día' : 'días'}, renueva pronto.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF92400E)),
          ),
        ),
      ]),
    );
  }

  // ─── Card de progreso circular ────────────────────────────────────────────

  Widget _progressCard(Membresia m) {
    final totalDias    = m.fechaVencimiento.difference(m.fechaInicio).inDays;
    final transcurridos = DateTime.now().difference(m.fechaInicio).inDays;
    final progreso     = totalDias <= 0
        ? 1.0
        : (transcurridos / totalDias).clamp(0.0, 1.0);
    final porcentaje   = (progreso * 100).toInt();
    final dias         = m.diasRestantes;
    final vencida      = m.estadoEfectivo == 'vencida';
    final Color arcColor = vencida
        ? AppColors.danger
        : (dias <= 5 ? AppColors.warning : AppColors.primary);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        // Círculo de progreso
        SizedBox(
          width: 172, height: 172,
          child: CustomPaint(
            painter: _CircularProgressPainter(
              progress: progreso,
              trackColor: AppColors.border,
              progressColor: arcColor,
              strokeWidth: 13,
            ),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  vencida ? '0' : '$dias',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 46, fontWeight: FontWeight.w800,
                    color: AppColors.text, letterSpacing: -2, height: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  dias == 1 && !vencida ? 'día\nrestante' : 'días\nrestantes',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5, color: AppColors.text2, height: 1.3),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 14),
        // Métricas
        Row(children: [
          Expanded(child: _metrica('$porcentaje%', 'consumido')),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(child: _metrica('$totalDias', 'días en total')),
        ]),
      ]),
    );
  }

  Widget _metrica(String valor, String label) {
    return Column(children: [
      Text(valor,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: AppColors.text, letterSpacing: -0.5)),
      const SizedBox(height: 2),
      Text(label,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text2)),
    ]);
  }

  // ─── Beneficios del plan ──────────────────────────────────────────────────

  Widget _beneficiosCard() {
    const items = [
      _Beneficio(Icons.all_inclusive_rounded,
          'Acceso ilimitado', 'Abierto los 7 días de la semana'),
      _Beneficio(Icons.fitness_center_rounded,
          'Zona de pesas', 'Equipos de musculación completos'),
      _Beneficio(Icons.person_rounded,
          'Asesoría de rutina', 'Orientación de nuestro personal'),
      _Beneficio(Icons.lock_open_rounded,
          'Casilleros y duchas', 'Vestuarios disponibles'),
    ];

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
          Text('Detalles del plan',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: AppColors.text, letterSpacing: -0.3)),
          const SizedBox(height: 14),
          ...List.generate(items.length, (i) {
            final last = i == items.length - 1;
            return Column(children: [
              _beneficioRow(items[i]),
              if (!last)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.border),
                ),
            ]);
          }),
        ],
      ),
    );
  }

  Widget _beneficioRow(_Beneficio b) {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(b.icon, color: AppColors.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.titulo,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text)),
          Text(b.subtitulo,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text2)),
        ]),
      ),
      const SizedBox(width: 8),
      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
    ]);
  }

  // ─── Sin membresía ────────────────────────────────────────────────────────

  Widget _sinMembresia() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        const Icon(Icons.card_membership_outlined, size: 48, color: AppColors.text3),
        const SizedBox(height: 14),
        Text('Sin membresía activa',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 8),
        Text('Acércate a la recepción para adquirir un plan.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: AppColors.text2, height: 1.4)),
      ]),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtFecha(DateTime d) {
    const m = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// ─── CustomPainter para progreso circular ─────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _CircularProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 13,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center, radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    if (progress <= 0) return;

    // Arco de progreso
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = progressColor,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}

// ─── Modelo local para beneficios ─────────────────────────────────────────

class _Beneficio {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  const _Beneficio(this.icon, this.titulo, this.subtitulo);
}
