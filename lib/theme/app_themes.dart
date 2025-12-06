import 'package:flutter/material.dart';

/// Enum para los diferentes temas disponibles
enum ThemeOption {
  blue,             // Azul (Default) - Material Design
  green,            // Verde - Naturaleza
  orange,           // Naranja - Energía
  teal,             // Teal - Profesional
  pink,             // Rosa - Moderno
  indigo,           // Índigo - Clásico
  brown,            // Marrón - Tierra
  red,              // Rojo - Pasión
  clubRed,          // Club Rojo profesional
  clubNeutralGreen, // Club Neutral Green Pro
}

/// Paletas disponibles para el usuario (solo estas 3)
const List<ThemeOption> availableThemes = [
  ThemeOption.blue,           // Azul (Default)
  ThemeOption.clubRed,        // Paleta Club Rojo
  ThemeOption.clubNeutralGreen, // Paleta Club Neutral Green Pro
];

/// Extensión para obtener nombre legible del tema
extension ThemeOptionName on ThemeOption {
  String get displayName {
    switch (this) {
      case ThemeOption.blue:
        return 'Azul (Por defecto)';
      case ThemeOption.green:
        return 'Verde';
      case ThemeOption.orange:
        return 'Naranja';
      case ThemeOption.teal:
        return 'Teal';
      case ThemeOption.pink:
        return 'Rosa';
      case ThemeOption.indigo:
        return 'Índigo';
      case ThemeOption.brown:
        return 'Marrón';
      case ThemeOption.red:
        return 'Rojo';
      case ThemeOption.clubRed:
        return 'Club Rojo';
      case ThemeOption.clubNeutralGreen:
        return 'Club Neutral Green Pro';
    }
  }

  String get displayNameEn {
    switch (this) {
      case ThemeOption.blue:
        return 'Blue (Default)';
      case ThemeOption.green:
        return 'Green';
      case ThemeOption.orange:
        return 'Orange';
      case ThemeOption.teal:
        return 'Teal';
      case ThemeOption.pink:
        return 'Pink';
      case ThemeOption.indigo:
        return 'Indigo';
      case ThemeOption.brown:
        return 'Brown';
      case ThemeOption.red:
        return 'Red';
      case ThemeOption.clubRed:
        return 'Club Red';
      case ThemeOption.clubNeutralGreen:
        return 'Club Neutral Green Pro';
    }
  }
}

/// Clase para manejar temas personalizados
class AppThemes {
  static const Map<ThemeOption, _ThemeConfig> themes = {
    ThemeOption.blue: _ThemeConfig(
      name: 'Azul',
      primary: Color(0xFF03A9F4),
      primaryDark: Color(0xFF0288D1),
      secondary: Color(0xFF4CAF50),
      accent: Color(0xFF4CAF50),
    ),
    ThemeOption.green: _ThemeConfig(
      name: 'Verde',
      primary: Color(0xFF4CAF50),
      primaryDark: Color(0xFF388E3C),
      secondary: Color(0xFF03A9F4),
      accent: Color(0xFF66BB6A),
    ),
    ThemeOption.orange: _ThemeConfig(
      name: 'Naranja',
      primary: Color(0xFFFF9800),
      primaryDark: Color(0xFFF57C00),
      secondary: Color(0xFF03A9F4),
      accent: Color(0xFFFFB74D),
    ),
    ThemeOption.teal: _ThemeConfig(
      name: 'Teal',
      primary: Color(0xFF009688),
      primaryDark: Color(0xFF00796B),
      secondary: Color(0xFF03A9F4),
      accent: Color(0xFF4DB6AC),
    ),
    ThemeOption.pink: _ThemeConfig(
      name: 'Rosa',
      primary: Color(0xFFE91E63),
      primaryDark: Color(0xFFC2185B),
      secondary: Color(0xFF03A9F4),
      accent: Color(0xFFF06292),
    ),
    ThemeOption.indigo: _ThemeConfig(
      name: 'Índigo',
      primary: Color(0xFF3F51B5),
      primaryDark: Color(0xFF283593),
      secondary: Color(0xFF4CAF50),
      accent: Color(0xFF5C6BC0),
    ),
    ThemeOption.brown: _ThemeConfig(
      name: 'Marrón',
      primary: Color(0xFF795548),
      primaryDark: Color(0xFF5D4037),
      secondary: Color(0xFF03A9F4),
      accent: Color(0xFFA1887F),
    ),
    ThemeOption.red: _ThemeConfig(
      name: 'Rojo',
      primary: Color(0xFFF44336),
      primaryDark: Color(0xFFd32f2f),
      secondary: Color(0xFF607d8b),
      accent: Color(0xFFffcdd2),
    ),
    ThemeOption.clubRed: _ThemeConfig(
      name: 'Club Rojo',
      primary: Color(0xFFB71C1C),
      primaryDark: Color(0xFF4A0A0A),
      secondary: Color(0xFFFF7043),
      accent: Color(0xFFFF7043),
    ),
    ThemeOption.clubNeutralGreen: _ThemeConfig(
      name: 'Club Neutral Green Pro',
      primary: Color(0xFF1B5E4A),
      primaryDark: Color(0xFF0D2A23),
      secondary: Color(0xFF00C896),
      accent: Color(0xFF00C896),
    ),
  };

  /// Obtener ThemeData para un tema específico
  static ThemeData getTheme(ThemeOption themeOption) {
    final config = themes[themeOption]!;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: config.primary,
        primary: config.primary,
        secondary: config.secondary,
        error: const Color(0xFFF44336),
        surface: const Color(0xFFFFFFFF),
        background: const Color(0xFFF5F5F5),
        brightness: Brightness.light,
      ),
      primaryColor: config.primary,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: config.primary,
        elevation: 2,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        titleTextStyle: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: config.primary,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: config.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primary,
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          elevation: 2,
          shadowColor: config.primary.withOpacity(0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: config.primary,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: config.primary,
          side: BorderSide(color: config.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: config.primary,
        unselectedItemColor: const Color(0xFF757575),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE3F2FD),
        selectedColor: config.primary,
        side: BorderSide(color: config.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF212121)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF212121)),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFF757575)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFFFFFFF)),
      ),
      extensions: [
        _ThemeExtension(
          primary: config.primary,
          primaryDark: config.primaryDark,
          secondary: config.secondary,
          accent: config.accent,
        ),
      ],
    );
  }

  /// Obtener un gradiente personalizado según el tema
  static LinearGradient getPrimaryGradient(ThemeOption themeOption) {
    final config = themes[themeOption]!;
    final start = _shadeColor(config.primaryDark, 0.1);
    final end = _tintColor(config.primary, 0.05);
    return LinearGradient(
      colors: [start, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Obtener un gradiente secundario
  static LinearGradient getSecondaryGradient(ThemeOption themeOption) {
    final config = themes[themeOption]!;
    final start = _shadeColor(config.secondary, 0.05);
    final end = _tintColor(config.accent, 0.1);
    return LinearGradient(
      colors: [start, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color _shadeColor(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount) ?? color;
  }

  static Color _tintColor(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }
}

/// Configuración interna de cada tema
class _ThemeConfig {
  final String name;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;

  const _ThemeConfig({
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
  });
}

/// Extensión de tema para acceder a colores personalizados
class _ThemeExtension extends ThemeExtension<_ThemeExtension> {
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;

  _ThemeExtension({
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
  });

  @override
  ThemeExtension<_ThemeExtension> copyWith({
    Color? primary,
    Color? primaryDark,
    Color? secondary,
    Color? accent,
  }) {
    return _ThemeExtension(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
    );
  }

  @override
  ThemeExtension<_ThemeExtension> lerp(ThemeExtension<_ThemeExtension>? other, double t) {
    if (other is! _ThemeExtension) {
      return this;
    }
    return _ThemeExtension(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t) ?? primaryDark,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
    );
  }
}

/// Extension en BuildContext para acceder fácilmente a los colores del tema actual
extension ThemeColorsExtension on BuildContext {
  /// Obtiene el gradiente primario del tema actual
  LinearGradient get primaryGradient {
    final theme = Theme.of(this);
    final custom = theme.extension<_ThemeExtension>();
    final primary = custom?.primary ?? theme.colorScheme.primary;
    final primaryDark = custom?.primaryDark ?? theme.colorScheme.primaryContainer;
    return LinearGradient(
      colors: [primaryDark, primary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Obtiene el color primario del tema actual
  Color get primaryColor {
    final theme = Theme.of(this);
    final custom = theme.extension<_ThemeExtension>();
    return custom?.primary ?? theme.colorScheme.primary;
  }

  /// Obtiene el color primario oscuro del tema actual
  Color get primaryDarkColor {
    final theme = Theme.of(this);
    final custom = theme.extension<_ThemeExtension>();
    return custom?.primaryDark ?? theme.colorScheme.primaryContainer;
  }

  /// Obtiene el color secundario del tema actual
  Color get secondaryColor {
    final theme = Theme.of(this);
    final custom = theme.extension<_ThemeExtension>();
    return custom?.secondary ?? theme.colorScheme.secondary;
  }
}
