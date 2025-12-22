import 'package:teampulse/theme/app_themes.dart';

class DashboardTeam {
  const DashboardTeam({
    required this.id,
    required this.name,
    this.teamCode,
    this.coachId,
    this.theme,
  });

  final String id;
  final String name;
  final String? teamCode;
  final String? coachId;
  final String? theme;

  ThemeOption? get themeOption {
    if (theme == null || theme!.isEmpty) return null;
    try {
      return ThemeOption.values.byName(theme!);
    } catch (_) {
      return null;
    }
  }
}
