import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Fundo violeta em degradê com formas decorativas, usado no login e nos
/// cabeçalhos. É a "assinatura" visual do app.
class VioletBackdrop extends StatelessWidget {
  const VioletBackdrop({
    super.key,
    this.child,
    this.borderRadius = BorderRadius.zero,
    this.showAccents = true,
  });

  final Widget? child;
  final BorderRadius borderRadius;

  /// Desenha também os anéis e pontos coloridos. Nos cabeçalhos, que são
  /// baixos e cheios de texto, fica desligado para nada cobrir o conteúdo.
  final bool showAccents;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: CustomPaint(
          painter: _BackdropPainter(showAccents: showAccents),
          child: child,
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.showAccents});

  final bool showAccents;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    final unit = size.shortestSide;

    // Círculos translúcidos grandes.
    fill.color = const Color(0x1FFFFFFF);
    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.06),
      unit * 0.42,
      fill,
    );
    fill.color = const Color(0x14FFFFFF);
    canvas.drawCircle(
      Offset(size.width * 0.02, size.height * 0.72),
      unit * 0.34,
      fill,
    );

    if (!showAccents) return;

    // Anéis finos.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x40FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.14, size.height * 0.10), 22, ring);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.88), 14, ring);

    // Pequenos acentos coloridos.
    fill.color = AppColors.mango;
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.20), 6, fill);
    fill.color = AppColors.mint;
    canvas.drawCircle(Offset(size.width * 0.26, size.height * 0.05), 4, fill);
    fill.color = AppColors.coral;
    canvas.drawCircle(Offset(size.width * 0.60, size.height * 0.94), 5, fill);
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.showAccents != showAccents;
}
