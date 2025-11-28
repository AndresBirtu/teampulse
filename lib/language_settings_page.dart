import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme/app_colors.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'language'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _LanguageTile(
            languageName: 'spanish'.tr(),
            locale: const Locale('es'),
            flag: '🇪🇸',
          ),
          _LanguageTile(
            languageName: 'english'.tr(),
            locale: const Locale('en'),
            flag: '🇬🇧',
          ),
          // Puedes agregar más idiomas aquí en el futuro
          // _LanguageTile(
          //   languageName: 'romanian'.tr(),
          //   locale: const Locale('ro'),
          //   flag: '🇷🇴',
          // ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String languageName;
  final Locale locale;
  final String flag;

  const _LanguageTile({
    required this.languageName,
    required this.locale,
    required this.flag,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = context.locale == locale;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Text(
          flag,
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(
          languageName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : Colors.black87,
            fontSize: 18,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
        onTap: () async {
          await context.setLocale(locale);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('language_changed'.tr()),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }
}
