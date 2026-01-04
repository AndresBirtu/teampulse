import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teampulse/services/preferences_service.dart';

class PlayerProfilePage extends StatefulWidget {
  final String teamId;
  final String playerId;

  const PlayerProfilePage({
    super.key,
    required this.teamId,
    required this.playerId,
  });

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  late TextEditingController photoUrlController;
  Map<String, dynamic>? playerData;
  bool _loading = true;
  bool _uploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    photoUrlController = TextEditingController();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('players')
          .doc(widget.playerId)
          .get();
      if (!doc.exists) {
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      if (mounted) {
        setState(() {
          playerData = doc.data();
          photoUrlController.text = playerData?['photoUrl'] ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando perfil: $e')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _guardarFoto() async {
    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('players')
          .doc(widget.playerId)
          .set({'photoUrl': photoUrlController.text.trim()}, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.playerId)
          .set({'photoUrl': photoUrlController.text.trim()}, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          playerData = {
            ...?playerData,
            'photoUrl': photoUrlController.text.trim(),
          };
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance.ref('users/${widget.playerId}/player-avatar.jpg');
      final bytes = await pickedFile.readAsBytes();
      final snapshot = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('players')
          .doc(widget.playerId)
          .set({'photoUrl': url}, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(widget.playerId).set({'photoUrl': url}, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          photoUrlController.text = url;
          playerData = {
            ...?playerData,
            'photoUrl': url,
          };
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada desde la galería')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la foto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _changeLanguage(Locale locale) async {
    if (!mounted) return;
    try {
      await context.setLocale(locale);
      await PreferencesService.setSelectedLanguage(locale.languageCode);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.playerId)
          .set({'preferredLanguage': locale.languageCode}, SetOptions(merge: true));

      if (!mounted) return;
      final languageName = locale.languageCode == 'es' ? 'Español' : 'English';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Idioma cambiado a $languageName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el idioma: $e')),
      );
    }
  }

  @override
  void dispose() {
    photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
        title: Text('profile'.tr()),
        elevation: 2,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = playerData?['name'] ?? 'Jugador';
    final photoUrl = photoUrlController.text;
    final initials = name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join();

    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr()),
        elevation: 2,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
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
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    onBackgroundImageError: photoUrl.isNotEmpty
                        ? (exception, stackTrace) {
                            // Handle image load errors silently
                          }
                        : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            initials.toUpperCase(),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Posición: ${playerData?['posicion'] ?? '-'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Foto de perfil',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
              icon: _uploadingPhoto
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_uploadingPhoto ? 'Subiendo...' : 'change_photo'.tr()),
            ),
          ),

          const SizedBox(height: 16),

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
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Español'),
                  trailing: context.locale.languageCode == 'es'
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary)
                      : null,
                  onTap: () => _changeLanguage(const Locale('es')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('English'),
                  trailing: context.locale.languageCode == 'en'
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary)
                      : null,
                  onTap: () => _changeLanguage(const Locale('en')),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Mis estadísticas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('Goles', playerData?['goles'] ?? 0),
                      _statItem('Asistencias', playerData?['asistencias'] ?? 0),
                      _statItem('Partidos', playerData?['partidos'] ?? 0),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('Minutos', playerData?['minutos'] ?? 0),
                      _statItem('Amarillas', playerData?['tarjetas_amarillas'] ?? 0),
                      _statItem('Rojas', playerData?['tarjetas_rojas'] ?? 0),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statItem(String label, dynamic value) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
