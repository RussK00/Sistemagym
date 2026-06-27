import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stanleygym_app/core/api/productos_service.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';
import 'package:stanleygym_app/core/widgets/accion_btn.dart';
import 'package:stanleygym_app/features/suplementos/models/producto.dart';

// ─── HU-09: Catálogo de productos (administrador) ─────────────────────────────
// Maneja productos del gimnasio por categoría (Suplemento, Bebida, Agua,
// Accesorio, Otro). Conectado al backend real (ProductosService).

// Variantes "soft" de color (no están en AppColors global).
const _primarySoft = Color(0xFFDBEAFE);
const _successSoft = Color(0xFFD1FAE5);
const _warningSoft = Color(0xFFFEF3C7);
const _dangerSoft  = Color(0xFFFEE2E2);
const _neutralSoft = Color(0xFFF1F5F9);
const _headerBg    = Color(0xFFF8FAFC);

class SuplementosScreen extends StatefulWidget {
  const SuplementosScreen({super.key});

  @override
  State<SuplementosScreen> createState() => _SuplementosScreenState();
}

class _SuplementosScreenState extends State<SuplementosScreen> {
  List<Producto> _productos = [];
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _filtroCat = 'Todos';
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
      final lista = await ProductosService.listar();
      if (!mounted) return;
      setState(() { _productos = lista; _loading = false; });
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

  List<Producto> get _filtered {
    final q = _query.toLowerCase();
    return _productos.where((p) {
      final matchQ = _query.isEmpty ||
        p.nombre.toLowerCase().contains(q) ||
        p.descripcion.toLowerCase().contains(q);
      final matchCat = _filtroCat == 'Todos' || p.categoria == _filtroCat;
      return matchQ && matchCat;
    }).toList();
  }

  int _countCat(String cat) =>
      cat == 'Todos' ? _productos.length : _productos.where((p) => p.categoria == cat).length;

  void _openForm({Producto? editing}) async {
    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.55),
      barrierDismissible: false,
      builder: (_) => _ProductoFormDialog(editing: editing),
    );
    if (datos == null) return;
    try {
      if (editing == null) {
        final nuevo = await ProductosService.crear(
          nombre:      datos['nombre'] as String,
          descripcion: datos['descripcion'] as String,
          categoria:   datos['categoria'] as String,
          precio:      datos['precio'] as double,
          stock:       datos['stock'] as int,
          imagenUrl:   datos['imagenUrl'] as String,
        );
        setState(() => _productos.insert(0, nuevo));
        _snack('Producto agregado correctamente.');
      } else {
        final actualizado = await ProductosService.actualizar(
          editing.id,
          nombre:      datos['nombre'] as String,
          descripcion: datos['descripcion'] as String,
          categoria:   datos['categoria'] as String,
          precio:      datos['precio'] as double,
          stock:       datos['stock'] as int,
          imagenUrl:   datos['imagenUrl'] as String,
        );
        setState(() {
          final i = _productos.indexWhere((p) => p.id == editing.id);
          if (i != -1) _productos[i] = actualizado;
        });
        _snack('Producto actualizado correctamente.');
      }
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  void _toggleActivo(Producto p) async {
    try {
      final actualizado = await ProductosService.cambiarEstado(p.id);
      setState(() {
        final i = _productos.indexWhere((x) => x.id == p.id);
        if (i != -1) _productos[i] = actualizado;
      });
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final activos  = _productos.where((p) => p.activo).length;
    final sinStock = _productos.where((p) => p.activo && p.stock == 0).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(activos, sinStock),
        const SizedBox(height: 18),
        _segmentedTabs(),
        const SizedBox(height: 16),
        Expanded(child: _contenido(rows)),
      ]),
    );
  }

  Widget _contenido(List<Producto> rows) {
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
    return _card(rows);
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _header(int activos, int sinStock) {
    return Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Productos',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
        Text('Suplementos, bebidas y accesorios — stock y precios.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text2)),
      ]),
      const Spacer(),
      ElevatedButton.icon(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, size: 16),
        label: Text('Agregar producto',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ]);
  }

  // ─── Segmented control de categorías ──────────────────────────────────────

  Widget _segmentedTabs() {
    final cats = ['Todos', ...Producto.categorias];
    return Container(
      decoration: BoxDecoration(
        color: _neutralSoft,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(children: cats.map(_tab).toList()),
    );
  }

  Widget _tab(String cat) {
    final active = _filtroCat == cat;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filtroCat = cat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 1))]
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_catIcon(cat), size: 15, color: active ? AppColors.primary : AppColors.text2),
            const SizedBox(width: 7),
            Flexible(child: Text(cat,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, fontWeight: FontWeight.w600,
                color: active ? AppColors.primary : AppColors.text2))),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active ? _primarySoft : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20)),
              child: Text('${_countCat(cat)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: active ? AppColors.primary : AppColors.text2)),
            ),
          ]),
        ),
      ),
    );
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Suplemento': return Icons.science_outlined;
      case 'Bebida':     return Icons.local_drink_outlined;
      case 'Agua':       return Icons.water_drop_outlined;
      case 'Accesorio':  return Icons.sell_outlined;
      case 'Otro':       return Icons.category_outlined;
      default:           return Icons.widgets_outlined; // Todos
    }
  }

  // ─── Tarjeta principal: barra + tabla + pie ───────────────────────────────

  Widget _card(List<Producto> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        _topBar(rows.length),
        _tableHeader(),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text('No hay productos que coincidan con el filtro.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3)))
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, i) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, i) => _row(rows[i]),
                ),
        ),
        _footer(rows.length),
      ]),
    );
  }

  Widget _topBar(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre…',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.text3),
              isDense: true,
              filled: true, fillColor: _headerBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
        ),
        const Spacer(),
        _Badge('$n productos', bg: _neutralSoft, fg: AppColors.text2),
      ]),
    );
  }

  Widget _tableHeader() {
    return Container(
      color: _headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
      child: Row(children: [
        _h('PRODUCTO', flex: 5),
        const SizedBox(width: 14),
        _h('CATEGORÍA', flex: 3),
        const SizedBox(width: 14),
        _h('STOCK', flex: 2, right: true),
        const SizedBox(width: 14),
        _h('PRECIO', flex: 2, right: true),
        const SizedBox(width: 30),
        _h('ESTADO', flex: 3),
        const SizedBox(width: 14),
        _h('', flex: 2, right: true),
      ]),
    );
  }

  Widget _h(String t, {required int flex, bool right = false}) => Expanded(
    flex: flex,
    child: Text(t,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: AppColors.text2, letterSpacing: 0.6)),
  );

  Widget _row(Producto p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
      child: Row(children: [
        // Producto: miniatura + nombre + descripción
        Expanded(flex: 5, child: Row(children: [
          p.imagenUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(p.imagenUrl, width: 44, height: 44, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _Thumb(abbr: _abbr(p.nombre), categoria: p.categoria)))
              : _Thumb(abbr: _abbr(p.nombre), categoria: p.categoria),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nombre,
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text),
              overflow: TextOverflow.ellipsis),
            if (p.descripcion.isNotEmpty)
              Text(p.descripcion,
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.text3),
                overflow: TextOverflow.ellipsis),
          ])),
        ])),
        const SizedBox(width: 14),
        // Categoría
        Expanded(flex: 3, child: Align(
          alignment: Alignment.centerLeft, child: _catBadge(p.categoria))),
        const SizedBox(width: 14),
        // Stock
        Expanded(flex: 2, child: Align(
          alignment: Alignment.centerRight, child: _stockBadge(p.stock))),
        const SizedBox(width: 14),
        // Precio
        Expanded(flex: 2, child: Text('S/ ${p.precio.toStringAsFixed(2)}',
          textAlign: TextAlign.right,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text,
            fontFeatures: const [FontFeature.tabularFigures()]))),
        const SizedBox(width: 30),
        // Estado
        Expanded(flex: 3, child: Align(
          alignment: Alignment.centerLeft, child: _estadoBadge(p))),
        const SizedBox(width: 14),
        // Acciones
        Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          AccionBtn(
            icon: Icons.edit_outlined, tooltip: 'Editar',
            onTap: () => _openForm(editing: p)),
          const SizedBox(width: 6),
          AccionBtn(
            icon: p.activo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            tooltip: p.activo ? 'Desactivar' : 'Activar',
            color: p.activo ? AppColors.danger : AppColors.success,
            onTap: () => _toggleActivo(p)),
        ])),
      ]),
    );
  }

  Widget _stockBadge(int stock) {
    Color bg, fg;
    if (stock == 0) { bg = _dangerSoft; fg = AppColors.danger; }
    else if (stock <= 10) { bg = _warningSoft; fg = AppColors.warning; }
    else { bg = _neutralSoft; fg = AppColors.text2; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text('$stock u.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5, fontWeight: FontWeight.w600, color: fg,
          fontFeatures: const [FontFeature.tabularFigures()])),
    );
  }

  Widget _estadoBadge(Producto p) {
    if (!p.activo) {
      return _Badge('Inactivo', bg: _neutralSoft, fg: AppColors.text2, dot: true);
    }
    if (p.stock == 0) {
      return _Badge('Agotado', bg: _dangerSoft, fg: AppColors.danger, dot: true);
    }
    return _Badge('Activo', bg: _successSoft, fg: AppColors.success, dot: true);
  }

  Widget _catBadge(String cat) {
    Color color, bg;
    switch (cat) {
      case 'Bebida':    color = const Color(0xFF047857); bg = _successSoft; break;
      case 'Agua':      color = const Color(0xFF1D4ED8); bg = _primarySoft; break;
      case 'Accesorio': color = const Color(0xFFB45309); bg = _warningSoft; break;
      case 'Otro':      color = const Color(0xFF7C3AED); bg = const Color(0xFFEDE9FE); break;
      default:          color = const Color(0xFF1D4ED8); bg = _primarySoft; // Suplemento
    }
    if (cat == 'Suplemento') { color = const Color(0xFF1D4ED8); bg = _primarySoft; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(cat,
        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _footer(int filtrados) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Text('Mostrando $filtrados de ${_productos.length} productos',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
        const Spacer(),
        Row(children: [
          _pageBtn(Icons.chevron_left_rounded),
          const SizedBox(width: 6),
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
            child: Text('1',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 6),
          _pageBtn(Icons.chevron_right_rounded),
        ]),
      ]),
    );
  }

  Widget _pageBtn(IconData icon) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: AppColors.border)),
    child: Icon(icon, size: 16, color: AppColors.text3),
  );

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _abbr(String nombre) {
    final w = nombre.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (w.isEmpty) return '?';
    if (w.length == 1) {
      return w[0].substring(0, w[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (w[0][0] + w[1][0]).toUpperCase();
  }
}

// ─── Badge reutilizable ───────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  final Color  bg, fg;
  final bool   dot;
  const _Badge(this.text, {required this.bg, required this.fg, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 5),
        ],
        Text(text,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

// ─── Miniatura con rayas diagonales (CustomPainter) ───────────────────────────

class _Thumb extends StatelessWidget {
  final String abbr;
  final String categoria;
  const _Thumb({required this.abbr, required this.categoria});

  @override
  Widget build(BuildContext context) {
    Color c1, c2, fg;
    switch (categoria) {
      case 'Bebida':    c1 = const Color(0xFFECFDF5); c2 = const Color(0xFFD1FAE5); fg = const Color(0xFF047857); break;
      case 'Agua':      c1 = const Color(0xFFEFF6FF); c2 = const Color(0xFFDBEAFE); fg = const Color(0xFF1D4ED8); break;
      case 'Accesorio': c1 = const Color(0xFFFEF3C7); c2 = const Color(0xFFFDE68A); fg = const Color(0xFFB45309); break;
      case 'Otro':      c1 = const Color(0xFFF5F3FF); c2 = const Color(0xFFEDE9FE); fg = const Color(0xFF7C3AED); break;
      default:          c1 = const Color(0xFFF1F5F9); c2 = const Color(0xFFE2E8F0); fg = AppColors.text3; // Suplemento
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44, height: 44,
        child: CustomPaint(
          painter: _StripePainter(c1, c2),
          child: Center(
            child: Text(abbr,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color c1, c2;
  _StripePainter(this.c1, this.c2);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = c1);
    final stripe = Paint()..color = c2;
    const band = 6.0;
    final h = size.height;
    // Bandas paralelas a 45°
    for (double x = -h; x < size.width + h; x += band * 2) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + band, 0)
        ..lineTo(x + band - h, h)
        ..lineTo(x - h, h)
        ..close();
      canvas.drawPath(path, stripe);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.c1 != c1 || old.c2 != c2;
}

// ─── Formulario de producto (crear / editar) ──────────────────────────────────

class _ProductoFormDialog extends StatefulWidget {
  final Producto? editing;
  const _ProductoFormDialog({this.editing});

  @override
  State<_ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<_ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _desc;
  late final TextEditingController _precio;
  late final TextEditingController _stock;
  late String _categoria;
  late String _imagenUrl;
  bool _subiendoImg = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nombre    = TextEditingController(text: e?.nombre ?? '');
    _desc      = TextEditingController(text: e?.descripcion ?? '');
    _precio    = TextEditingController(text: e?.precio.toStringAsFixed(2) ?? '');
    _stock     = TextEditingController(text: e?.stock.toString() ?? '');
    _categoria = e?.categoria ?? 'Suplemento';
    _imagenUrl = e?.imagenUrl ?? '';
  }

  Future<void> _pickImagen() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(
      source: ImageSource.gallery, maxWidth: 1000, imageQuality: 80);
    if (img == null) return;
    setState(() => _subiendoImg = true);
    try {
      final bytes = await img.readAsBytes();
      final url = await ProductosService.subirImagen(bytes, img.name);
      if (!mounted) return;
      setState(() { _imagenUrl = url; _subiendoImg = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _subiendoImg = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', ''),
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  void dispose() {
    _nombre.dispose(); _desc.dispose(); _precio.dispose(); _stock.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      'nombre':      _nombre.text.trim(),
      'descripcion': _desc.text.trim(),
      'categoria':   _categoria,
      'precio':      double.parse(_precio.text.trim()),
      'stock':       int.parse(_stock.text.trim()),
      'imagenUrl':   _imagenUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 16, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isEdit ? 'Editar producto' : 'Agregar producto',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text('Registra un suplemento, bebida o accesorio en el catálogo.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.text2)),
              ])),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.text3),
                ),
              ),
            ]),
          ),
          // Body
          Flexible(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Imagen del producto'),
              const SizedBox(height: 8),
              _imagenPicker(),
              const SizedBox(height: 16),

              _label('Categoría *'),
              const SizedBox(height: 8),
              Row(children: Producto.categorias.map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _catCard(c),
                ),
              )).toList()),
              const SizedBox(height: 16),

              _label('Nombre del producto *'),
              const SizedBox(height: 5),
              _field(_nombre, _hintNombre(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
              const SizedBox(height: 14),

              _label('Descripción'),
              const SizedBox(height: 5),
              _field(_desc, 'Ej: Proteína de suero, sabor chocolate'),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Stock inicial (u.) *'),
                  const SizedBox(height: 5),
                  _field(_stock, '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      if (int.tryParse(v.trim()) == null) return 'Inválido';
                      return null;
                    }),
                ])),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Precio de venta (S/) *'),
                  const SizedBox(height: 5),
                  _field(_precio, '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Precio inválido';
                      return null;
                    }),
                ])),
              ]),
            ])),
          )),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: AppColors.text2),
                child: Text('Cancelar',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500))),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(isEdit ? Icons.save_outlined : Icons.add, size: 16),
                label: Text(isEdit ? 'Guardar cambios' : 'Agregar producto',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  String _hintNombre() {
    switch (_categoria) {
      case 'Bebida':    return 'Ej. Sporade Tropical 500ml';
      case 'Agua':      return 'Ej. Agua San Luis 625ml';
      case 'Accesorio': return 'Ej. Shaker 600ml';
      default:          return 'Ej. Whey Protein 1kg';
    }
  }

  Widget _catCard(String c) {
    final active = _categoria == c;
    IconData icon;
    switch (c) {
      case 'Suplemento': icon = Icons.science_outlined; break;
      case 'Bebida':     icon = Icons.local_drink_outlined; break;
      case 'Agua':       icon = Icons.water_drop_outlined; break;
      case 'Accesorio':  icon = Icons.sell_outlined; break;
      default:           icon = Icons.category_outlined;
    }
    return GestureDetector(
      onTap: () => setState(() => _categoria = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? _primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : AppColors.border2, width: active ? 1.5 : 1),
          boxShadow: active
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.10), blurRadius: 6, spreadRadius: 1)]
              : null,
        ),
        child: Column(children: [
          Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.text2),
          const SizedBox(height: 5),
          Text(c,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5, fontWeight: FontWeight.w600,
              color: active ? AppColors.primary : AppColors.text2)),
        ]),
      ),
    );
  }

  Widget _imagenPicker() {
    final tieneImg = _imagenUrl.isNotEmpty;
    return Row(children: [
      // Vista previa / placeholder
      GestureDetector(
        onTap: _subiendoImg ? null : _pickImagen,
        child: Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border2),
          ),
          clipBehavior: Clip.antiAlias,
          child: _subiendoImg
              ? const Center(child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)))
              : tieneImg
                  ? Image.network(_imagenUrl, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: AppColors.text3))
                  : const Icon(Icons.add_photo_alternate_outlined, size: 26, color: AppColors.text3),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OutlinedButton.icon(
          onPressed: _subiendoImg ? null : _pickImagen,
          icon: const Icon(Icons.upload_rounded, size: 16),
          label: Text(tieneImg ? 'Cambiar imagen' : 'Subir imagen',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (tieneImg) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _subiendoImg ? null : () => setState(() => _imagenUrl = ''),
            icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
            label: Text('Quitar',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.danger)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('JPG o PNG, hasta 5 MB.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.text3)),
          ),
      ])),
    ]);
  }

  Widget _label(String t) => Text(t,
    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text));

  Widget _field(TextEditingController c, String hint, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.text3),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
      ),
    );
  }
}
