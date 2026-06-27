import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/pagos_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/pagos/models/pago.dart';

// ─── HU-08: Historial de pagos (recepcionista) ────────────────────────────────
// Los pagos de membresía se registran AUTOMÁTICAMENTE al asignar/renovar una
// membresía (ver membresiasController.js → INSERT en pagos en la misma
// transacción). Esta pantalla es solo de consulta del historial.

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  List<Pago> _pagos = [];
  final TextEditingController _search = TextEditingController();
  String _query = '';
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
      final pagos = await PagosService.listar();
      if (!mounted) return;
      setState(() {
        _pagos   = pagos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Pago> get _filtered {
    final list = _query.isEmpty
        ? _pagos
        : _pagos.where((p) =>
            p.nombreSocio.toLowerCase().contains(_query.toLowerCase()) ||
            p.concepto.toLowerCase().contains(_query.toLowerCase())).toList();
    return list..sort((a, b) => b.fechaPago.compareTo(a.fechaPago));
  }

  double get _totalRecaudado => _pagos.fold(0.0, (s, p) => s + p.monto);

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(),
        const SizedBox(height: 16),
        _resumen(),
        const SizedBox(height: 16),
        _toolbar(),
        const SizedBox(height: 16),
        Expanded(child: _contenido(rows)),
      ]),
    );
  }

  Widget _contenido(List<Pago> rows) {
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
    return _table(rows);
  }

  Widget _header() {
    return Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pagos',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.4)),
        Text('Historial de pagos. Las membresías registran su pago al asignarse o renovarse.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
      ]),
      const Spacer(),
      OutlinedButton.icon(
        onPressed: _loading ? null : _cargar,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: Text('Actualizar',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ]);
  }

  Widget _resumen() {
    final ahora = DateTime.now();
    final delMes = _pagos.where((p) =>
      p.fechaPago.month == ahora.month && p.fechaPago.year == ahora.year)
      .fold(0.0, (s, p) => s + p.monto);

    return Row(children: [
      _card('Total recaudado', 'S/. ${_totalRecaudado.toStringAsFixed(0)}',
        Icons.account_balance_wallet_rounded, AppColors.success, const Color(0xFFF0FDF4)),
      const SizedBox(width: 16),
      _card('Recaudado este mes', 'S/. ${delMes.toStringAsFixed(0)}',
        Icons.calendar_month_rounded, AppColors.primary, const Color(0xFFEFF6FF)),
      const SizedBox(width: 16),
      _card('N° de pagos', '${_pagos.length}',
        Icons.receipt_long_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
    ]);
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
          child: Icon(icon, color: color, size: 20),
        ),
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

  Widget _toolbar() {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
        decoration: InputDecoration(
          hintText: 'Buscar por socio o concepto…',
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.text3),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
        ),
      ),
    );
  }

  Widget _table(List<Pago> rows) {
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
              _th('Socio',    flex: 3),
              _th('Concepto', flex: 3),
              _th('Monto',    flex: 2),
              _th('Método',   flex: 2),
              _th('Fecha',    flex: 2),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: rows.isEmpty
                ? Center(child: Text('Sin pagos registrados.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text2)))
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

  Widget _row(Pago p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(p.nombreSocio[0],
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(p.nombreSocio,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text),
            overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 3, child: Text(p.concepto,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2),
          overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text('S/. ${p.monto.toStringAsFixed(0)}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.success))),
        Expanded(flex: 2, child: Row(children: [
          Icon(p.metodoPago == 'efectivo' ? Icons.payments_rounded : Icons.account_balance_rounded,
            size: 14, color: AppColors.text3),
          const SizedBox(width: 5),
          Text(_cap(p.metodoPago),
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
        ])),
        Expanded(flex: 2, child: Text(_fmtFecha(p.fechaPago),
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2))),
      ]),
    );
  }

  Widget _th(String label, {required int flex}) => Expanded(
    flex: flex,
    child: Text(label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2, letterSpacing: 0.4)),
  );

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
