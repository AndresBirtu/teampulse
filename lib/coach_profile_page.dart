import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'theme/app_themes.dart';
import 'services/preferences_service.dart';

class CoachProfilePage extends StatefulWidget {
  final ThemeOption? currentTheme;
  final Function(ThemeOption)? onThemeChanged;

  const CoachProfilePage({
    this.currentTheme,
    this.onThemeChanged,
    super.key,
  });

  @override
  State<CoachProfilePage> createState() => _CoachProfilePageState();
}

class _CoachProfilePageState extends State<CoachProfilePage> {
  String? _coachPhotoUrl;
  String? _coachName;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadCoachProfile();
  }

  Future<void> _loadCoachProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      if (mounted) {
        setState(() {
          _coachPhotoUrl = data['photoUrl'] as String?;
          _coachName = data['name'] as String?;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickCoachPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance.ref('users/${user.uid}/coach-avatar.jpg');
      final bytes = await picked.readAsBytes();
      final snapshot = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'photoUrl': url}, SetOptions(merge: true));

      if (mounted) {
        setState(() => _coachPhotoUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subiendo foto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr()),
        elevation: 2,
      ),
      body: ListView(
        children: [
          // SECCIÓN: INFORMACIÓN DEL PERFIL
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Foto de perfil
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    backgroundImage: (_coachPhotoUrl != null && _coachPhotoUrl!.isNotEmpty)
                        ? NetworkImage(_coachPhotoUrl!)
                        : null,
                    child: (_coachPhotoUrl == null || _coachPhotoUrl!.isEmpty)
                        ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _coachName ?? 'coach_profile'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _uploadingPhoto ? null : _pickCoachPhoto,
                  icon: _uploadingPhoto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(_uploadingPhoto ? 'Subiendo...' : 'change_photo'.tr()),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // SECCIÓN: APARIENCIA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'appearance'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Selector de Tema
          if (widget.currentTheme != null && widget.onThemeChanged != null)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('theme'.tr()),
                subtitle: Text(
                  context.locale.languageCode == 'en'
                      ? widget.currentTheme?.displayNameEn ?? 'Blue'
                      : widget.currentTheme?.displayName ?? 'Azul',
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showThemeDialog(context);
                },
              ),
            ),

          const SizedBox(height: 16),

          // SECCIÓN: IDIOMA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'language'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('change_language'.tr()),
              subtitle: Text(
                context.locale.languageCode == 'en' ? 'English' : 'Español',
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showLanguageDialog(context);
              },
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('select_theme'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final theme in availableThemes)
                ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppThemes.getTheme(theme).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    context.locale.languageCode == 'en'
                        ? theme.displayNameEn
                        : theme.displayName,
                  ),
                  trailing: widget.currentTheme == theme
                      ? Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    // Llamar el callback para actualizar MyApp
                    widget.onThemeChanged?.call(theme);
                    // Guardar en preferencias
                    PreferencesService.setSelectedTheme(theme);
                    Navigator.pop(dialogContext);
                    // Mostrar snackbar
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('theme_changed'.tr()),
                          ),
                        );
                      }
                    });
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('change_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Español'),
              trailing: context.locale.languageCode == 'es'
                  ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary)
                  : null,
              onTap: () async {
                await context.setLocale(const Locale('es'));
                await PreferencesService.setSelectedLanguage('es');
                if (mounted) {
                  Navigator.pop(dialogContext);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('language_changed'.tr()),
                        ),
                      );
                    }
                  });
                }
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: context.locale.languageCode == 'en'
                  ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary)
                  : null,
              onTap: () async {
                await context.setLocale(const Locale('en'));
                await PreferencesService.setSelectedLanguage('en');
                if (mounted) {
                  Navigator.pop(dialogContext);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('language_changed'.tr()),
                        ),
                      );
                    }
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }
}
