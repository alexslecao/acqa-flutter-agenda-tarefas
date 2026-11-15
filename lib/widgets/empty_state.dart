import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Ilustração simples com título e mensagem, usada para lista vazia e erros.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Botão opcional exibido abaixo da mensagem.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final action = this.action;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.lavender,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 60, color: AppColors.violet),
                  ),
                  const Positioned(
                    right: 6,
                    top: 10,
                    child: _Dot(color: AppColors.mango, size: 18),
                  ),
                  const Positioned(
                    left: 2,
                    bottom: 22,
                    child: _Dot(color: AppColors.mint, size: 12),
                  ),
                  const Positioned(
                    right: 20,
                    bottom: 0,
                    child: _Dot(color: AppColors.coral, size: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.inkSoft,
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 18),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
