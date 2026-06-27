import 'package:flutter/material.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';

/// Botón de acción cuadrado con borde, usado en las tablas del panel
/// (editar, activar/desactivar con el ícono de ojo, eliminar, etc.).
///
/// Uso típico para activar/desactivar:
/// ```dart
/// AccionBtn(
///   icon: activo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
///   tooltip: activo ? 'Desactivar' : 'Activar',
///   color: activo ? AppColors.danger : AppColors.success,
///   onTap: () => _toggle(item),
/// )
/// ```
class AccionBtn extends StatelessWidget {
  final IconData     icon;
  final String       tooltip;
  final VoidCallback onTap;
  final Color?       color;

  const AccionBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border2),
          ),
          child: Icon(icon, size: 16, color: color ?? AppColors.text2),
        ),
      ),
    );
  }
}
