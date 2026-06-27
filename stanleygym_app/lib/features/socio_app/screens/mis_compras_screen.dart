import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/ventas_service.dart';
import 'package:stanleygym_app/core/auth/usuario_rol.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/ventas/models/venta.dart';

// ─── HU-12: Mis compras (app móvil del socio) ─────────────────────────────────

class MisComprasScreen extends StatefulWidget {
  final UsuarioSesion usuario;
  const MisComprasScreen({super.key, required this.usuario});

  @override
  State<MisComprasScreen> createState() => _MisComprasScreenState();
}

class _MisComprasScreenState extends State<MisComprasScreen> {
  int _filtro = 0; // 0: todo | 1: este mes
  List<Venta> _todas = [];
  bool   _loading = true;
  String? _error;

  static const _meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await VentasService.porSocio(widget.usuario.idSocio!);
      if (!mounted) return;
      setState(() { _todas = lista; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Venta> get _misCompras {
    final todas = List<Venta>.of(_todas)
      ..sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));

    if (_filtro == 1) {
      final ahora = DateTime.now();
      return todas.where((v) =>
        v.fechaVenta.month == ahora.month && v.fechaVenta.year == ahora.year).toList();
    }
    return todas;
  }

  @override
  Widget build(BuildContext context) {
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
    final compras = _misCompras;
    final totalGastado = _todas.fold(0.0, (s, v) => s + v.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mis compras',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text('Tus compras de suplementos en el gimnasio.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)),
        const SizedBox(height: 18),

        // Resumen total gastado
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
            boxShadow: [BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 7),
              Text('Total gastado en suplementos',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
            ]),
            const SizedBox(height: 10),
            Text('S/. ${totalGastado.toStringAsFixed(0)}',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1, height: 1)),
          ]),
        ),
        const SizedBox(height: 18),

        // Filtros
        Row(children: [
          _chip(0, 'Todo'),
          const SizedBox(width: 8),
          _chip(1, 'Este mes'),
        ]),
        const SizedBox(height: 16),

        if (compras.isEmpty)
          _emptyState()
        else
          ...compras.map(_tile),
      ]),
    );
  }

  Widget _chip(int index, String label) {
    final active = _filtro == index;
    return GestureDetector(
      onTap: () => setState(() => _filtro = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.border2),
        ),
        child: Text(label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.text2)),
      ),
    );
  }

  Widget _tile(Venta v) {
    final f = v.fechaVenta;
    final fecha = '${f.day} ${_meses[f.month - 1]} ${f.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF7C3AED), size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v.nombreProducto,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
            overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(children: [
            Text('${v.cantidad} u. × S/. ${v.precioUnitario.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text2)),
            Text('  ·  $fecha',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text3)),
          ]),
        ])),
        Text('S/. ${v.total.toStringAsFixed(0)}',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: -0.3)),
      ]),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        const Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.text3),
        const SizedBox(height: 10),
        Text('Aún no tienes compras',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.text2)),
        const SizedBox(height: 4),
        Text('Tus compras de suplementos aparecerán aquí.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text3)),
      ]),
    );
  }
}
