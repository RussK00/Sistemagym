import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/socio_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/socio_app/models/notificacion.dart';

// ─── HU-05: Notificaciones del socio (in-app) ─────────────────────────────────

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<Notificacion> _items = [];
  bool   _loading = true;
  String? _error;

  static const _meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await SocioService.misNotificaciones();
      if (!mounted) return;
      setState(() { _items = lista; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _marcarLeida(Notificacion n) async {
    if (n.leida) return;
    try {
      await SocioService.marcarLeida(n.id);
      setState(() {
        final i = _items.indexWhere((x) => x.id == n.id);
        if (i != -1) {
          _items[i] = Notificacion(
            id: n.id, titulo: n.titulo, mensaje: n.mensaje, tipo: n.tipo,
            leida: true, fechaCreacion: n.fechaCreacion);
        }
      });
    } catch (_) {/* silencioso */}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Notificaciones',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
        iconTheme: const IconThemeData(color: AppColors.text),
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
        ]),
      ));
    }
    if (_items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.text3),
        const SizedBox(height: 12),
        Text('No tienes notificaciones',
          style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 4),
        Text('Aquí verás los avisos sobre tu membresía.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _tile(_items[i]),
    );
  }

  Widget _tile(Notificacion n) {
    return GestureDetector(
      onTap: () => _marcarLeida(n),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.leida ? Colors.white : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: n.leida ? AppColors.border : const Color(0xFFFDE68A)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n.titulo,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text))),
              if (!n.leida)
                Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 4),
            Text(n.mensaje,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2, height: 1.4)),
            const SizedBox(height: 6),
            Text(_fecha(n.fechaCreacion),
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.text3)),
          ])),
        ]),
      ),
    );
  }

  String _fecha(DateTime d) {
    final h = '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    return '${d.day} ${_meses[d.month - 1]} · $h';
  }
}
