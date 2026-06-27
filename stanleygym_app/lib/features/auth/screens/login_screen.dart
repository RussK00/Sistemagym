import 'dart:math' show pi;
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stanleygym_app/core/api/auth_service.dart';
import 'package:stanleygym_app/core/auth/usuario_rol.dart';
import 'package:stanleygym_app/core/theme/app_colors.dart';

// ─── CustomPainters ──────────────────────────────────────────────────────────

class StanleyLogoPainter extends CustomPainter {
  final Color color;
  const StanleyLogoPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32;

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = color;

    // Placas izquierda
    fill.color = color.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2 * s, 10 * s, 3.2 * s, 12 * s),
        Radius.circular(1.2 * s),
      ),
      fill,
    );
    fill.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5.6 * s, 7 * s, 2.4 * s, 18 * s),
        Radius.circular(s),
      ),
      fill,
    );

    // Placas derecha (espejadas)
    fill.color = color.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(26.8 * s, 10 * s, 3.2 * s, 12 * s),
        Radius.circular(1.2 * s),
      ),
      fill,
    );
    fill.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24 * s, 7 * s, 2.4 * s, 18 * s),
        Radius.circular(s),
      ),
      fill,
    );

    // Barra con doble curva en S
    canvas.drawPath(
      Path()
        ..moveTo(9 * s, 14.2 * s)
        ..cubicTo(11 * s, 13 * s, 14 * s, 13 * s, 16 * s, 14.2 * s)
        ..cubicTo(18 * s, 15.4 * s, 21 * s, 15.4 * s, 23 * s, 14.2 * s)
        ..moveTo(23 * s, 17.8 * s)
        ..cubicTo(21 * s, 19 * s, 18 * s, 19 * s, 16 * s, 17.8 * s)
        ..cubicTo(14 * s, 16.6 * s, 11 * s, 16.6 * s, 9 * s, 17.8 * s),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DumbbellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shader = LinearGradient(
      colors: [
        Colors.transparent,
        AppColors.accentBlue.withValues(alpha: 0.45),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;

    // Barra central
    final barH = h * 0.10;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, (h - barH) / 2, w, barH),
        const Radius.circular(4),
      ),
      paint,
    );

    final pw = w * 0.055;
    final gap = w * 0.008;
    const leftH = [0.85, 0.65, 0.45];
    const rightH = [0.45, 0.65, 0.85];
    final lx = w * 0.05;
    final rx = w * 0.95 - 3 * (pw + gap);

    for (int i = 0; i < 3; i++) {
      final lph = h * leftH[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(lx + i * (pw + gap), (h - lph) / 2, pw, lph),
          const Radius.circular(3),
        ),
        paint,
      );
      final rph = h * rightH[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rx + i * (pw + gap), (h - rph) / 2, pw, rph),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final r = size.width / 2;
    final c = Offset(r, r);
    final circ = 2 * pi * r;
    const dash = 5.0;
    const gap = 5.0;
    final n = (circ / (dash + gap)).floor();
    final step = 2 * pi / n;
    final sweep = step * (dash / (dash + gap));
    for (int i = 0; i < n; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * step,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) =>
      Path()..addRect(Rect.fromLTRB(0, 0, size.width, size.height / 2));

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─── Panel izquierdo ─────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cs) {
        final w = cs.maxWidth;
        final h = cs.maxHeight;
        final fs = (w * 0.14).clamp(64.0, 104.0);

        return ClipRect(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF0B1220),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1a. Capa radial — arriba izquierda
                Positioned(
                  top: -150,
                  left: -150,
                  child: Container(
                    width: 800,
                    height: 800,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF1E40AF).withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        radius: 0.6,
                      ),
                    ),
                  ),
                ),
                // 1b. Capa radial — abajo derecha
                Positioned(
                  bottom: -150,
                  right: -150,
                  child: Container(
                    width: 700,
                    height: 700,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF1E293B).withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                        radius: 0.6,
                      ),
                    ),
                  ),
                ),
                // 2. Glow orb
                Positioned(
                  top: -120,
                  right: -120,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 480,
                      height: 480,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 3. Grid sutil con fade radial
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, 0.40, 0.85],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                ),
                // 4a. Línea diagonal 1 — 62%
                Positioned(
                  top: h * 0.62,
                  left: 0,
                  right: 0,
                  child: Transform.rotate(
                    angle: -8 * pi / 180,
                    child: Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF60A5FA),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 4b. Línea diagonal 2 — 70%
                Positioned(
                  top: h * 0.70,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.35,
                    child: Transform.rotate(
                      angle: -8 * pi / 180,
                      child: Container(
                        height: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF60A5FA),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 5. Anillo decorativo
                Positioned(
                  right: -90,
                  bottom: -90,
                  child: SizedBox(
                    width: 360,
                    height: 360,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentBlue.withValues(
                                alpha: 0.18,
                              ),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 80,
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            width: 312,
                            height: 312,
                            child: CustomPaint(painter: _DashedCirclePainter()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 6. Silueta de mancuerna
                Positioned(
                  top: h * 0.14,
                  right: w * 0.08,
                  child: Transform.rotate(
                    angle: -22 * pi / 180,
                    child: CustomPaint(
                      painter: _DumbbellPainter(),
                      size: const Size(420, 170),
                    ),
                  ),
                ),
                // 7. Contenido
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 56,
                      vertical: 64,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_header(), _hero(fs), _footer()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              painter: const StanleyLogoPainter(color: Colors.white),
              size: const Size(30, 30),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Stalin Pro Gym',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _hero(double fs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // STANLEY — degradado blanco vertical
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE2E8F0)],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'STALIN PRO',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: fs,
              fontWeight: FontWeight.w800,
              height: 0.92,
              letterSpacing: -4.5,
              color: Colors.white,
            ),
          ),
        ),
        // GYM — outline azul + relleno degradado en mitad superior
        Stack(
          children: [
            Text(
              'GYM',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: fs,
                fontWeight: FontWeight.w800,
                height: 0.92,
                letterSpacing: -4.5,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = AppColors.accentBlue,
              ),
            ),
            ClipPath(
              clipper: _TopHalfClipper(),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.accentBlue, AppColors.primary],
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'GYM',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: fs,
                    fontWeight: FontWeight.w800,
                    height: 0.92,
                    letterSpacing: -4.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              color: const Color(0xFFCBD5E1),
              height: 1.55,
            ),
            children: const [
              TextSpan(
                text: 'Gestiona socios, asistencia, suplementos y planes ',
              ),
              TextSpan(
                text: 'desde un solo panel',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: ' — diseñado para el día a día del administrador.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return const Text(
      '© 2026 Stalinprogym',
      style: TextStyle(
        color: Color(0xFF64748B),
        fontSize: 12,
        letterSpacing: 0.7,
      ),
    );
  }
}

// ─── LoginScreen ─────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final void Function(UsuarioSesion usuario, bool recordar) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(
    text: kIsWeb ? 'recepcionista@gmail.com' : 'carlos.rios@gmail.com',
  );
  final _pwd = TextEditingController();
  final _emailFocus = FocusNode();
  final _pwdFocus = FocusNode();

  bool showPassword = false;
  bool remember = true;
  bool loading = false;
  bool _emailFocused = false;
  bool _pwdFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(
      () => setState(() => _emailFocused = _emailFocus.hasFocus),
    );
    _pwdFocus.addListener(
      () => setState(() => _pwdFocused = _pwdFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pwd.dispose();
    _emailFocus.dispose();
    _pwdFocus.dispose();
    super.dispose();
  }

  String? _errorMsg;

  Future<void> _submit() async {
    setState(() {
      loading = true;
      _errorMsg = null;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final resultado = await AuthService.login(
      _email.text,
      _pwd.text,
      esWeb: kIsWeb,
    );
    if (!mounted) return;
    setState(() => loading = false);

    if (resultado.usuario == null) {
      setState(() => _errorMsg = resultado.error);
      return;
    }
    widget.onLogin(resultado.usuario!, remember);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: LayoutBuilder(
        builder: (context, cs) {
          final narrow = cs.maxWidth < 980;

          if (narrow) {
            return Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _form(),
                  ),
                ),
              ),
            );
          }

          return Row(
            children: [
              const Expanded(flex: 52, child: _LeftPanel()),
              Expanded(flex: 48, child: _rightPanel()),
            ],
          );
        },
      ),
    );
  }

  Widget _rightPanel() {
    return Stack(
      children: [
        Container(color: Colors.white),
        // Borde izquierdo degradado
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.border,
                  AppColors.border,
                  Colors.transparent,
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _form(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Iniciar sesión',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.75,
            color: AppColors.text,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          kIsWeb
              ? 'Ingresa tus credenciales para acceder al panel administrativo.'
              : 'Ingresa tus credenciales de socio para consultar tu membresía.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.text2,
          ),
        ),
        const SizedBox(height: 30),
        _label('Correo electrónico'),
        const SizedBox(height: 6),
        _emailField(),
        const SizedBox(height: 18),
        _label('Contraseña'),
        const SizedBox(height: 6),
        _passwordField(),
        const SizedBox(height: 18),
        _rememberRow(),
        const SizedBox(height: 18),
        if (_errorMsg != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMsg!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFFDC2626),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        _button(),
      ],
    );
  }

  Widget _label(String t) => Text(
    t,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.text,
    ),
  );

  InputDecoration _fieldDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
    bool hasRightPadding = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.text3),
      prefixIcon: Icon(icon, size: 16, color: AppColors.text3),
      prefixIconConstraints: const BoxConstraints(minWidth: 38),
      suffixIcon: suffix,
      suffixIconConstraints: suffix != null
          ? const BoxConstraints(minWidth: 36, maxWidth: 36)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ).copyWith(right: hasRightPadding ? 44 : 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  Widget _glowWrap({required bool focused, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  Widget _emailField() {
    return _glowWrap(
      focused: _emailFocused,
      child: TextField(
        controller: _email,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.text),
        cursorColor: AppColors.primary,
        decoration: _fieldDeco(
          hint: 'recepcionista@gmail.com',
          icon: Icons.mail_outline,
        ),
      ),
    );
  }

  Widget _passwordField() {
    return _glowWrap(
      focused: _pwdFocused,
      child: TextField(
        controller: _pwd,
        focusNode: _pwdFocus,
        obscureText: !showPassword,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.text),
        cursorColor: AppColors.primary,
        decoration: _fieldDeco(
          hint: '••••••••',
          icon: Icons.lock_outline,
          hasRightPadding: true,
          suffix: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility_off : Icons.visibility,
              size: 16,
              color: AppColors.text3,
            ),
            onPressed: () => setState(() => showPassword = !showPassword),
            splashRadius: 18,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ),
      ),
    );
  }

  Widget _rememberRow() {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: remember,
            onChanged: (v) => setState(() => remember = v ?? remember),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Recordarme',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.text2,
          ),
        ),
      ],
    );
  }

  Widget _button() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : _submit,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
              elevation: 0,
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return AppColors.primaryDark;
                }
                return AppColors.primary;
              }),
              overlayColor: WidgetStatePropertyAll(
                AppColors.primaryDark.withValues(alpha: 0.1),
              ),
            ),
        child: Text(loading ? 'Ingresando…' : 'Iniciar sesión'),
      ),
    );
  }
}
