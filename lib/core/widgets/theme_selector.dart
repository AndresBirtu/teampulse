import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:teampulse/theme/app_themes.dart';

/// Widget para seleccionar tema
class ThemeSelector extends StatelessWidget {
  final ThemeOption currentTheme;
  final Function(ThemeOption) onThemeChanged;

  const ThemeSelector({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppThemes.getPrimaryGradient(currentTheme),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.palette, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  locale == 'en' ? 'Select Theme' : 'Selecciona un Tema',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              shrinkWrap: true,
              itemCount: availableThemes.length,
              itemBuilder: (context, index) {
                final theme = availableThemes[index];
                final isSelected = currentTheme == theme;
                final themeName = locale == 'en'
                    ? theme.displayNameEn
                    : theme.displayName;

                return _ThemeOptionCard(
                  theme: theme,
                  isSelected: isSelected,
                  themeName: themeName,
                  onTap: () {
                    onThemeChanged(theme);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: Text(
                locale == 'en' ? 'Close' : 'Cerrar',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final ThemeOption theme;
  final bool isSelected;
  final String themeName;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.theme,
    required this.isSelected,
    required this.themeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = AppThemes.getTheme(theme);
    final primaryColor = themeData.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppThemes.getSecondaryGradient(theme),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Text(
                themeName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ThemeSettings extends StatelessWidget {
  final ThemeOption currentTheme;
  final Function(ThemeOption) onThemeChanged;

  const ThemeSettings({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final themeName = locale == 'en'
        ? currentTheme.displayNameEn
        : currentTheme.displayName;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.palette),
        title: Text(
          locale == 'en' ? 'Theme' : 'Tema',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(themeName),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => ThemeSelector(
              currentTheme: currentTheme,
              onThemeChanged: onThemeChanged,
            ),
          );
        },
      ),
    );
  }
}
