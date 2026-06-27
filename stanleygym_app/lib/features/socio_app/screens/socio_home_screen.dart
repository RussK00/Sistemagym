import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/socio_service.dart';
import 'package:stanleygym_app/core/auth/usuario_rol.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/asistencia/models/asistencia.dart';
import 'package:stanleygym_app/features/membresias/models/membresia.dart';
import 'package:stanleygym_app/features/socio_app/screens/mis_compras_screen.dart';
import 'package:stanleygym_app/features/socio_app/screens/notificaciones_screen.dart';

class SocioHomeScreen extends StatefulWidget {
  final UsuarioSesion usuario;
  final ValueChanged<int> onNavigate; // 1=membresía 2=asistencia 3=perfil

  const SocioHomeScreen({
    super.key,
    required this.usuario,
    required this.onNavigate,
  });

  @override
  State<SocioHomeScreen> createState() => _SocioHomeScreenState();
}

class _SocioHomeScreenState extends State<SocioHomeScreen> {
  Membresia? _membresia;
  List<Asistencia> _asistencias = [];
  int _noLeidas = 0;
  bool _loading = true;
  String? _error;

  static const _meses = [
    'Ene','Feb','Mar','Abr','May','Jun',
    'Jul','Ago','Sep','Oct','Nov','Dic',
  ];
  static const _diasSem = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final mem        = await SocioService.miMembresia();
      final asistencias = await SocioService.miAsistencia();
      final notifs     = await SocioService.misNotificaciones();
      if (!mounted) return;
      asistencias.sort((a, b) => b.fechaHoraIngreso.compareTo(a.fechaHoraIngreso));
      setState(() {
        _membresia   = mem;
        _asistencias = asistencias.take(3).toList();
        _noLeidas    = notifs.where((n) => !n.leida).length;
        _loading     = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _abrirNotificaciones() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
    );
    // refrescar contador al volver
    try {
      final notifs = await SocioService.misNotificaciones();
      if (!mounted) return;
      setState(() => _noLeidas = notifs.where((n) => !n.leida).length);
    } catch (_) {}
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header + card flotante ────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              _header(),
              Positioned(
                bottom: -56,
                left: 20,
                right: 20,
                child: _cardMembresia(),
              ),
            ],
          ),
          const SizedBox(height: 56 + 24),

          // ── Cuerpo ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _accesosRapidos(),
                const SizedBox(height: 24),
                _ultimaAsistencia(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header con gradiente ─────────────────────────────────────────────────

  Widget _header() {
    final primerNombre = widget.usuario.nombre.split(' ').first;
    final mem = _membresia;
    final estado = mem?.estadoEfectivo ?? '';
    final activa = estado == 'activa';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navy],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superior: logo + campana
          Row(
            children: [
              // Monograma SG
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Center(
                  child: Text(
                    'SG',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'StalinProGym',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              // Campana de notificaciones
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: _abrirNotificaciones,
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Notificaciones',
                  ),
                  if (_noLeidas > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Saludo + badge de estado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola,',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '$primerNombre 👋',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (mem != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: activa
                        ? const Color(0xFF16A34A)
                        : AppColors.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activa
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        activa ? 'Activa ✓' : 'Vencida',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Card flotante de membresía ──────────────────────────────────────────

  Widget _cardMembresia() {
    final mem = _membresia;

    if (mem == null) {
      return GestureDetector(
        onTap: () => widget.onNavigate(1),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_membership_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No tienes membresía activa',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
            ],
          ),
        ),
      );
    }

    final estado     = mem.estadoEfectivo;
    final dias       = mem.diasRestantes;
    final vencida    = estado == 'vencida';
    final porVencer  = !vencida && dias <= 7;
    final totalDias  = mem.fechaVencimiento.difference(mem.fechaInicio).inDays;
    final transcurridos = DateTime.now().difference(mem.fechaInicio).inDays;
    final progreso   = totalDias <= 0 ? 1.0 : (transcurridos / totalDias).clamp(0.0, 1.0);

    final Color statusColor;
    final String statusLabel;
    if (vencida) {
      statusColor = AppColors.danger;
      statusLabel = 'Vencida';
    } else if (porVencer) {
      statusColor = AppColors.warning;
      statusLabel = 'Por vencer';
    } else {
      statusColor = AppColors.success;
      statusLabel = 'Activa';
    }

    return GestureDetector(
      onTap: () => widget.onNavigate(1),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan + badge
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan actual',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.text2),
                    ),
                    Text(
                      mem.nombrePlan,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                  ],
                ),
                const Spacer(),
                // Badge de estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Días restantes
            if (!vencida)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$dias',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 42, fontWeight: FontWeight.w800,
                      color: AppColors.text, letterSpacing: -2, height: 1),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      dias == 1 ? 'día restante' : 'días restantes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text2),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tu plan venció',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.danger)),
                  Text('Acércate a recepción para renovar.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text2)),
                ],
              ),

            const SizedBox(height: 12),

            // Barra de progreso + fechas
            if (!vencida) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    porVencer ? AppColors.warning : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progreso * 100).toInt()}% del período',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.text3),
                  ),
                  Text(
                    'Vence ${_fmtFecha(mem.fechaVencimiento)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text3),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Accesos rápidos 2×2 ─────────────────────────────────────────────────

  Widget _accesosRapidos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos rápidos',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.text, letterSpacing: -0.3),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _accesoCard(Icons.card_membership_rounded, 'Ver\nmembresía',
                () => widget.onNavigate(1)),
            _accesoCard(Icons.calendar_month_rounded,  'Mi\nasistencia',
                () => widget.onNavigate(2)),
            _accesoCard(Icons.medical_services_rounded, 'Mis compras',
                _irACompras),
            _accesoCard(Icons.account_circle_rounded,  'Mi perfil',
                () => widget.onNavigate(3)),
          ],
        ),
      ],
    );
  }

  Widget _accesoCard(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, fontWeight: FontWeight.w600,
                color: AppColors.text, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  void _irACompras() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.text),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Mis compras',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
          ),
          body: SafeArea(
            child: MisComprasScreen(usuario: widget.usuario),
          ),
        ),
      ),
    );
  }

  // ─── Última asistencia ────────────────────────────────────────────────────

  Widget _ultimaAsistencia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Última asistencia',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.text, letterSpacing: -0.3),
            ),
            GestureDetector(
              onTap: () => widget.onNavigate(2),
              child: Text(
                'Ver todo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_asistencias.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Sin registros de asistencia',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(_asistencias.length, (i) {
                final ultimo = i == _asistencias.length - 1;
                return Column(
                  children: [
                    _asistenciaTile(_asistencias[i]),
                    if (!ultimo)
                      const Divider(
                        height: 1,
                        color: AppColors.border,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _asistenciaTile(Asistencia a) {
    final f    = a.fechaHoraIngreso;
    final hora = '${f.hour.toString().padLeft(2,'0')}:${f.minute.toString().padLeft(2,'0')}';
    final now  = DateTime.now();
    final esHoy = f.year == now.year && f.month == now.month && f.day == now.day;
    final diaSem = _diasSem[f.weekday - 1];
    final etiqueta = esHoy ? 'Hoy' : '$diaSem ${f.day} ${_meses[f.month - 1]}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Círculo check verde
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Día + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text),
                ),
                Text(
                  'Ingreso registrado',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.text3),
                ),
              ],
            ),
          ),
          // Hora con ícono
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: AppColors.text3),
              const SizedBox(width: 4),
              Text(
                hora,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtFecha(DateTime d) {
    const mesesLargos = [
      'Ene','Feb','Mar','Abr','May','Jun',
      'Jul','Ago','Sep','Oct','Nov','Dic',
    ];
    return '${d.day} ${mesesLargos[d.month - 1]} ${d.year}';
  }
}
