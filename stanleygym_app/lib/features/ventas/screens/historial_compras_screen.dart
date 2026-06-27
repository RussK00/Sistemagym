import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/socios_service.dart';
import 'package:stanleygym_app/core/api/ventas_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/socios/models/socio.dart';
import 'package:stanleygym_app/features/ventas/models/venta.dart';

// ─── HU-11: Historial de compras por socio (administrador) ────────────────────

class HistorialComprasScreen extends StatefulWidget {
  const HistorialComprasScreen({super.key});

  @override
  State<HistorialComprasScreen> createState() => _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreen> {
  Socio?      _socio;
  List<Socio> _socios  = [];
  List<Venta> _compras = [];
  bool   _cargandoSocios  = true;
  bool   _cargandoCompras = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSocios();
  }

  Future<void> _cargarSocios() async {
    setState(() { _cargandoSocios = true; _error = null; });
    try {
      final lista = await SociosService.listar();
      if (!mounted) return;
      setState(() { _socios = lista; _cargandoSocios = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargandoSocios = false; });
    }
  }

  Future<void> _seleccionarSocio(Socio? s) async {
    setState(() { _socio = s; _compras = []; });
    if (s == null) return;
    setState(() => _cargandoCompras = true);
    try {
      final lista = await VentasService.porSocio(s.id);
      if (!mounted) return;
      setState(() { _compras = lista; _cargandoCompras = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _cargandoCompras = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalGastado = _compras.fold(0.0, (s, v) => s + v.total);
    final unidades = _compras.fold(0, (s, v) => s + v.cantidad);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(),
        const SizedBox(height: 20),
        _selectorSocio(),
        const SizedBox(height: 20),
        if (_error != null)
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.text3),
            const SizedBox(height: 10),
            Text(_error!, textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _cargarSocios,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Reintentar', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ])))
        else if (_socio == null)
          Expanded(child: _placeholderInicial())
        else if (_cargandoCompras)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else ...[
          Row(children: [
            _card('Total gastado', 'S/. ${totalGastado.toStringAsFixed(0)}',
              Icons.account_balance_wallet_rounded, AppColors.success, const Color(0xFFF0FDF4)),
            const SizedBox(width: 16),
            _card('Compras realizadas', '${_compras.length}',
              Icons.receipt_long_rounded, AppColors.primary, const Color(0xFFEFF6FF)),
            const SizedBox(width: 16),
            _card('Unidades adquiridas', '$unidades',
              Icons.inventory_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
          ]),
          const SizedBox(height: 20),
          Expanded(child: _table(_compras)),
        ],
      ]),
    );
  }

  Widget _header() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Historial de compras por socio',
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.4)),
      Text('Selecciona un socio para ver todas sus compras de suplementos.',
        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
    ]);
  }

  Widget _selectorSocio() {
    return SizedBox(
      width: 360,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Socio',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text)),
        const SizedBox(height: 5),
        DropdownButtonFormField<Socio>(
          initialValue: _socio,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            prefixIcon: const Icon(Icons.person_search_rounded, size: 18, color: AppColors.text3),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          hint: Text('Selecciona un socio',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3)),
          items: _socios.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s.nombreCompleto,
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text)))).toList(),
          onChanged: _cargandoSocios ? null : _seleccionarSocio,
        ),
      ]),
    );
  }

  Widget _card(String label, String value, IconData icon, Color color, Color bg) {
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
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.5)),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text2)),
        ]),
      ]),
    ));
  }

  Widget _table(List<Venta> rows) {
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
              _th('Producto', flex: 4),
              _th('Cantidad', flex: 2),
              _th('P. Unit.', flex: 2),
              _th('Total',    flex: 2),
              _th('Fecha',    flex: 2),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: rows.isEmpty
                ? _sinCompras()
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, i) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) => _row(rows[i]),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _row(Venta v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 4, child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.inventory_2_rounded, size: 16, color: Color(0xFF7C3AED))),
          const SizedBox(width: 10),
          Flexible(child: Text(v.nombreProducto,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text),
            overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 2, child: Text('${v.cantidad} u.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2))),
        Expanded(flex: 2, child: Text('S/. ${v.precioUnitario.toStringAsFixed(0)}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2))),
        Expanded(flex: 2, child: Text('S/. ${v.total.toStringAsFixed(0)}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.success))),
        Expanded(flex: 2, child: Text(_fmtFecha(v.fechaVenta),
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2))),
      ]),
    );
  }

  Widget _sinCompras() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.text3),
    const SizedBox(height: 10),
    Text('Este socio no tiene compras registradas',
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.text2)),
  ]));

  Widget _placeholderInicial() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: 64, height: 64,
      decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
      child: const Icon(Icons.person_search_rounded, size: 30, color: AppColors.primary)),
    const SizedBox(height: 14),
    Text('Selecciona un socio',
      style: GoogleFonts.bricolageGrotesque(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
    const SizedBox(height: 4),
    Text('Elige un socio en el menú de arriba para ver su historial de compras.',
      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
  ]));

  Widget _th(String label, {required int flex}) => Expanded(
    flex: flex,
    child: Text(label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 0.4)),
  );

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}
