import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/productos_service.dart';
import 'package:stanleygym_app/core/api/socios_service.dart';
import 'package:stanleygym_app/core/api/ventas_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/features/socios/models/socio.dart';
import 'package:stanleygym_app/features/suplementos/models/producto.dart';
import 'package:stanleygym_app/features/ventas/models/venta.dart';

// ─── HU-10: Registro de compra de suplementos (recepcionista) ─────────────────

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  List<Venta>    _ventas    = [];
  List<Socio>    _socios    = [];
  List<Producto> _productos = [];
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
      final results = await Future.wait([
        VentasService.listar(),
        SociosService.listar(),
        ProductosService.listar(),
      ]);
      if (!mounted) return;
      setState(() {
        _ventas    = results[0] as List<Venta>;
        _socios    = results[1] as List<Socio>;
        _productos = results[2] as List<Producto>;
        _loading   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  List<Venta> get _filtered {
    final list = _query.isEmpty
        ? _ventas
        : _ventas.where((v) =>
            v.nombreSocio.toLowerCase().contains(_query.toLowerCase()) ||
            v.nombreProducto.toLowerCase().contains(_query.toLowerCase())).toList();
    return list..sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
  }

  void _registrarVenta() async {
    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VentaFormDialog(socios: _socios, productos: _productos),
    );
    if (datos == null) return;
    try {
      final venta = await VentasService.crear(
        idSocio:    datos['idSocio'] as int,
        idProducto: datos['idProducto'] as int,
        cantidad:   datos['cantidad'] as int,
      );
      // Recargar para reflejar el stock descontado
      final productos = await ProductosService.listar();
      if (!mounted) return;
      setState(() {
        _ventas.insert(0, venta);
        _productos = productos;
      });
      _snack('Compra registrada correctamente.');
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final totalVendido = _ventas.fold(0.0, (s, v) => s + v.total);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(),
        const SizedBox(height: 16),
        _resumen(totalVendido),
        const SizedBox(height: 16),
        _toolbar(),
        const SizedBox(height: 16),
        Expanded(child: _contenido(rows)),
      ]),
    );
  }

  Widget _contenido(List<Venta> rows) {
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
        Text('Compras de suplementos',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.4)),
        Text('Registra las compras de productos a nombre de un socio.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
      ]),
      const Spacer(),
      FilledButton.icon(
        onPressed: _registrarVenta,
        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
        label: Text('Registrar compra',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ]);
  }

  Widget _resumen(double totalVendido) {
    final ahora = DateTime.now();
    final delMes = _ventas.where((v) =>
      v.fechaVenta.month == ahora.month && v.fechaVenta.year == ahora.year)
      .fold(0.0, (s, v) => s + v.total);
    final unidades = _ventas.fold(0, (s, v) => s + v.cantidad);

    return Row(children: [
      _card('Total vendido', 'S/. ${totalVendido.toStringAsFixed(0)}',
        Icons.account_balance_wallet_rounded, AppColors.success, const Color(0xFFF0FDF4)),
      const SizedBox(width: 16),
      _card('Vendido este mes', 'S/. ${delMes.toStringAsFixed(0)}',
        Icons.calendar_month_rounded, AppColors.primary, const Color(0xFFEFF6FF)),
      const SizedBox(width: 16),
      _card('Unidades vendidas', '$unidades',
        Icons.inventory_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
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

  Widget _toolbar() {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
        decoration: InputDecoration(
          hintText: 'Buscar por socio o producto…',
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
              _th('Socio',     flex: 3),
              _th('Producto',  flex: 3),
              _th('Cant.',     flex: 1),
              _th('P. Unit.',  flex: 2),
              _th('Total',     flex: 2),
              _th('Fecha',     flex: 2),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: rows.isEmpty
                ? Center(child: Text('Sin compras registradas.',
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

  Widget _row(Venta v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(v.nombreSocio[0],
              style: GoogleFonts.bricolageGrotesque(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
          const SizedBox(width: 8),
          Flexible(child: Text(v.nombreSocio,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text),
            overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 3, child: Text(v.nombreProducto,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2),
          overflow: TextOverflow.ellipsis)),
        Expanded(flex: 1, child: Text('${v.cantidad}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text))),
        Expanded(flex: 2, child: Text('S/. ${v.precioUnitario.toStringAsFixed(0)}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2))),
        Expanded(flex: 2, child: Text('S/. ${v.total.toStringAsFixed(0)}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.success))),
        Expanded(flex: 2, child: Text(_fmtFecha(v.fechaVenta),
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
}

// ─── Formulario de compra ─────────────────────────────────────────────────────

class _VentaFormDialog extends StatefulWidget {
  final List<Socio>    socios;
  final List<Producto> productos;
  const _VentaFormDialog({required this.socios, required this.productos});

  @override
  State<_VentaFormDialog> createState() => _VentaFormDialogState();
}

class _VentaFormDialogState extends State<_VentaFormDialog> {
  final _formKey  = GlobalKey<FormState>();
  Socio?    _socio;
  Producto? _producto;
  String    _catFiltro = 'Todos';
  final _cantidadCtrl = TextEditingController(text: '1');

  int get _cantidad => int.tryParse(_cantidadCtrl.text.trim()) ?? 0;
  double get _total => _producto == null ? 0 : _producto!.precio * _cantidad;

  // Productos activos del catálogo (el admin controla la visibilidad).
  List<Producto> get _activos => widget.productos.where((p) => p.activo).toList();

  // Categorías que tienen al menos un producto activo (+ "Todos").
  List<String> get _categorias => [
    'Todos',
    ...Producto.categorias.where((c) => _activos.any((p) => p.categoria == c)),
  ];

  // Productos visibles según la categoría elegida.
  // Los agotados se muestran pero deshabilitados (no se pueden vender sin stock).
  List<Producto> get _disponibles => _activos
      .where((p) => _catFiltro == 'Todos' || p.categoria == _catFiltro)
      .toList();

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_socio == null || _producto == null) return;

    Navigator.of(context).pop({
      'idSocio':    _socio!.id,
      'idProducto': _producto!.id,
      'cantidad':   _cantidad,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(key: _formKey, child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Registrar compra',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
                Text('Selecciona el socio y el producto comprado.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
              ])),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.text3)),
            ]),
            const SizedBox(height: 20),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),

            _label('Socio *'),
            const SizedBox(height: 5),
            DropdownButtonFormField<Socio>(
              initialValue: _socio,
              isExpanded: true,
              decoration: _deco(),
              hint: Text('Selecciona un socio',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3)),
              items: widget.socios.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.nombreCompleto,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text)))).toList(),
              onChanged: (v) => setState(() => _socio = v),
              validator: (v) => v == null ? 'Selecciona un socio' : null,
            ),
            const SizedBox(height: 14),

            _label('Producto *'),
            const SizedBox(height: 5),
            // Filtro por categoría
            if (_categorias.length > 1) ...[
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categorias.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final c = _categorias[i];
                    final active = _catFiltro == c;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _catFiltro = c;
                        _producto = null; // evita un valor fuera del nuevo filtro
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? AppColors.primary : AppColors.border2),
                        ),
                        child: Text(c,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppColors.text2)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            DropdownButtonFormField<Producto>(
              key: ValueKey(_catFiltro),
              initialValue: _producto,
              isExpanded: true,
              decoration: _deco(),
              hint: Text('Selecciona un producto',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3)),
              items: _disponibles.map((p) {
                final agotado = p.stock <= 0;
                return DropdownMenuItem(
                  value: p,
                  enabled: !agotado, // los agotados se ven pero no se eligen
                  child: Row(children: [
                    Expanded(child: Text(p.nombre,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: agotado ? AppColors.text3 : AppColors.text),
                      overflow: TextOverflow.ellipsis)),
                    Text(
                      agotado
                          ? 'Agotado'
                          : 'S/. ${p.precio.toStringAsFixed(0)} · stock ${p.stock}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: agotado ? FontWeight.w700 : FontWeight.w400,
                        color: agotado ? AppColors.danger : AppColors.text2)),
                  ]));
              }).toList(),
              onChanged: (v) => setState(() => _producto = v),
              validator: (v) => v == null ? 'Selecciona un producto' : null,
            ),
            if (_disponibles.isEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _catFiltro == 'Todos'
                    ? 'No hay productos activos disponibles.'
                    : 'No hay productos activos en la categoría "$_catFiltro".',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.danger)),
            ],
            const SizedBox(height: 14),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Cantidad *'),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _cantidadCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
                  decoration: _fieldDeco('1'),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Cantidad inválida';
                    if (_producto != null && n > _producto!.stock) {
                      return 'Solo hay ${_producto!.stock} en stock';
                    }
                    return null;
                  },
                ),
              ])),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Total a cobrar'),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0))),
                  child: Row(children: [
                    const Icon(Icons.payments_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text('S/. ${_total.toStringAsFixed(0)}',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success, letterSpacing: -0.5)),
                  ]),
                ),
              ])),
            ]),

            const SizedBox(height: 22),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: AppColors.text2),
                child: Text('Cancelar',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500))),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text('Registrar compra',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ]),
          ])),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text));

  InputDecoration _fieldDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
  );

  InputDecoration _deco() => InputDecoration(
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
  );
}
