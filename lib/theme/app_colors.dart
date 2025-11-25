import 'package:flutter/material.dart';

/*
TeamPulse Design Guide:

- Usar colores de AppColors para mantener coherencia en toda la app.
- Colores principales: AppColors.primary, AppColors.primaryLight, AppColors.primaryDark
- Colores secundarios: AppColors.secondary, AppColors.secondaryLight, AppColors.secondaryDark
- Colores de acento: AppColors.accent, AppColors.accentLight
- Estados: success, warning, error, info
- Disponibilidad de jugadores: available, maybe, notAvailable
- Eventos: matchColor, trainingColor, matchPlayed
- Estadísticas: goals, assists, yellowCard, redCard
- Fondos y superficies: background, surface, surfaceVariant
- Textos: textPrimary, textSecondary, textHint, textOnPrimary
- Gradientes: primaryGradient, matchGradient, trainingGradient, statsGradient

Instrucciones para Copilot:
- Para Widgets de AppBar, Cards, Buttons: usar colores primarios y gradientes según contexto.
- Para indicadores de eventos (partidos, entrenamientos): usar matchGradient o trainingGradient.
- Para estadísticas (goles, asistencias, tarjetas): usar colores correspondientes.
- Para fondos de pantallas: usar AppColors.background o AppColors.surface.
- Mantener coherencia de tipografía y colores en toda la app.
- Aplicar bordes redondeados y sombras suaves en Cards y Buttons.
- Todos los Widgets deben poder usarse tanto en móvil como en escritorio.
*/

/// Paleta de colores profesional para TeamPulse
class AppColors {
  // Colores principales (basados en Material Design)
  static const Color primary = Color(0xFF03A9F4); // Primary color - Azul vibrante
  static const Color primaryLight = Color(0xFFB3E5FC); // Light primary color - Azul muy claro
  static const Color primaryDark = Color(0xFF0288D1); // Dark primary color - Azul oscuro
  
  // Colores secundarios y acento
  static const Color secondary = Color(0xFF4CAF50); // Accent color - Verde Material
  static const Color secondaryLight = Color(0xFF81C784); // Verde claro
  static const Color secondaryDark = Color(0xFF388E3C); // Verde oscuro
  
  // Colores de acento adicionales
  static const Color accent = Color(0xFF4CAF50); // Verde acento principal
  static const Color accentLight = Color(0xFF81C784); // Verde acento claro
  
  // Estados
  static const Color success = Color(0xFF4CAF50); // Verde éxito (accent color)
  static const Color warning = Color(0xFFFF9800); // Naranja advertencia
  static const Color error = Color(0xFFF44336); // Rojo error Material
  static const Color info = Color(0xFF03A9F4); // Azul información (primary)
  
  // Disponibilidad
  static const Color available = Color(0xFF4CAF50); // Verde - Confirmado (accent)
  static const Color maybe = Color(0xFFFF9800); // Naranja - Dudoso
  static const Color notAvailable = Color(0xFFF44336); // Rojo - No asiste
  
  // Eventos
  static const Color matchColor = Color(0xFF03A9F4); // Azul para partidos (primary)
  static const Color trainingColor = Color(0xFF4CAF50); // Verde para entrenamientos (accent)
  static const Color matchPlayed = Color(0xFF757575); // Gris para partidos jugados (secondary text)
  
  // Estadísticas
  static const Color goals = Color(0xFFFFB300); // Dorado para goles
  static const Color assists = Color(0xFF00BCD4); // Cyan para asistencias
  static const Color yellowCard = Color(0xFFFFEB3B); // Amarillo tarjetas
  static const Color redCard = Color(0xFFF44336); // Rojo tarjetas
  
  // Fondos y superficies
  static const Color background = Color(0xFFF5F5F5); // Gris muy claro
  static const Color surface = Color(0xFFFFFFFF); // Blanco
  static const Color surfaceVariant = Color(0xFFE3F2FD); // Azul muy claro variant
  static const Color divider = Color(0xFFBDBDBD); // Divider color
  
  // Textos
  static const Color textPrimary = Color(0xFF212121); // Primary text
  static const Color textSecondary = Color(0xFF757575); // Secondary text
  static const Color textHint = Color(0xFFBDBDBD); // Hint text / Divider
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Text / Icons on primary
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0288D1), Color(0xFF03A9F4)], // Dark to primary
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient matchGradient = LinearGradient(
    colors: [Color(0xFF03A9F4), Color(0xFFB3E5FC)], // Primary to light
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient trainingGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF81C784)], // Accent green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient statsGradient = LinearGradient(
    colors: [Color(0xFF03A9F4), Color(0xFF4CAF50)], // Primary to accent
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
