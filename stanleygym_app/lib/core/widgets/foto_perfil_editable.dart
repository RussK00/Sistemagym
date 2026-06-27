import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stanleygym_app/core/api/auth_service.dart';
import 'package:stanleygym_app/core/auth/session.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';

/// Avatar de perfil editable: muestra la foto del usuario (o su inicial),
/// y al tocarlo permite elegir una nueva imagen y subirla.
class FotoPerfilEditable extends StatefulWidget {
  final double radius;
  final VoidCallback? onActualizada; // para refrescar la pantalla padre
  const FotoPerfilEditable({super.key, this.radius = 32, this.onActualizada});

  @override
  State<FotoPerfilEditable> createState() => _FotoPerfilEditableState();
}

class _FotoPerfilEditableState extends State<FotoPerfilEditable> {
  bool _subiendo = false;

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (img == null) return;

    setState(() => _subiendo = true);
    try {
      final url = await AuthService.subirFoto(img.path);
      Session.actual?.fotoUrl = url;
      if (!mounted) return;
      setState(() => _subiendo = false);
      widget.onActualizada?.call();
      _snack('Foto de perfil actualizada.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _subiendo = false);
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
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

  @override
  Widget build(BuildContext context) {
    final u = Session.actual;
    final r = widget.radius;

    return GestureDetector(
      onTap: _subiendo ? null : _cambiarFoto,
      child: Stack(
        children: [
          AvatarPerfil(fotoUrl: u?.fotoUrl, inicial: u?.inicial ?? '?', radius: r),
          // Cargando
          if (_subiendo)
            Positioned.fill(child: CircleAvatar(
              radius: r,
              backgroundColor: Colors.black.withValues(alpha: 0.45),
              child: const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
            )),
          // Botón de cámara
          if (!_subiendo)
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Avatar de solo lectura: muestra la foto si existe, si no la inicial.
class AvatarPerfil extends StatelessWidget {
  final String? fotoUrl;
  final String  inicial;
  final double  radius;
  final Color   bgColor;
  final Color   textColor;

  const AvatarPerfil({
    super.key,
    required this.fotoUrl,
    required this.inicial,
    this.radius = 20,
    this.bgColor = AppColors.primary,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE2E8F0),
        backgroundImage: NetworkImage(fotoUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(inicial,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: radius * 0.8, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}
