import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Marca do app: um cartão branco levemente inclinado com um calendário e um
/// ponto de destaque.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Transform.rotate(
            angle: -0.14,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.3),
                boxShadow: AppShadows.card,
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: size * 0.56,
                color: AppColors.violet,
              ),
            ),
          ),
          Positioned(
            right: -size * 0.06,
            top: -size * 0.06,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: AppColors.mango,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
