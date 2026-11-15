import 'package:material_ui/material_ui.dart';

/// Paleta do Lavanda: violeta intenso, lavanda, branco e pequenos acentos.
abstract final class AppColors {
  static const Color deepViolet = Color(0xFF34107A);
  static const Color violet = Color(0xFF6D28D9);
  static const Color grape = Color(0xFF9056F5);
  static const Color lavender = Color(0xFFE6DAFF);
  static const Color mist = Color(0xFFF6F2FF);

  /// Texto principal (quase preto, puxado para o roxo).
  static const Color ink = Color(0xFF1F1442);

  /// Texto secundário, com contraste suficiente sobre branco e lavanda.
  static const Color inkSoft = Color(0xFF62588A);

  // Acentos.
  static const Color mango = Color(0xFFFFB84D);
  static const Color coral = Color(0xFFFF6F91);
  static const Color mint = Color(0xFF34D6A8);
  static const Color sky = Color(0xFF57C7FF);

  static const Color danger = Color(0xFFC81E5B);

  /// Cores usadas na lateral dos cartões de tarefa.
  static const List<Color> taskAccents = <Color>[mango, coral, sky, mint, grape];
}

abstract final class AppGradients {
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.deepViolet,
      AppColors.violet,
      AppColors.grape,
    ],
    stops: <double>[0.0, 0.58, 1.0],
  );
}

abstract final class AppShadows {
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F34107A),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(
      color: Color(0x1434107A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.violet,
      onPrimary: Colors.white,
      secondary: AppColors.mango,
      onSecondary: AppColors.ink,
      surface: Colors.white,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      onError: Colors.white,
    );

    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.mist,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.violet,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  /// Aparência padrão dos campos de texto do app.
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.violet),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.mist,
      labelStyle: const TextStyle(color: AppColors.inkSoft),
      hintStyle: const TextStyle(color: AppColors.inkSoft),
      errorMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: border(AppColors.lavender, 1.2),
      enabledBorder: border(AppColors.lavender, 1.2),
      focusedBorder: border(AppColors.violet, 2),
      errorBorder: border(AppColors.danger, 1.4),
      focusedErrorBorder: border(AppColors.danger, 2),
    );
  }
}
