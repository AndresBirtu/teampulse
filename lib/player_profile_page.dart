import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'services/preferences_service.dart';

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
          title: const Text('Mi perfil'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = playerData?['name'] ?? 'Jugador';
    final photoUrl = photoUrlController.text;
    final initials = name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar actual
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor.withOpacity(0.12),
                      image: photoUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(photoUrl),
                              fit: BoxFit.cover,
                              onError: (_, __) => SizedBox.shrink(),
                            )
                          : null,
                    ),
                    child: photoUrl.isEmpty
                        ? Center(
                            child: Text(
                              initials.toUpperCase(),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Posición: ${playerData?['posicion'] ?? '-'}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Formulario de foto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Foto de perfil',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: photoUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL de tu foto',
                        hintText: 'https://example.com/foto.jpg',
                        border: const OutlineInputBorder(),
                        suffixIcon: Icon(Icons.photo, color: Theme.of(context).primaryColor),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    if (photoUrlController.text.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                          image: DecorationImage(
                            image: NetworkImage(photoUrlController.text),
                            fit: BoxFit.cover,
                            onError: (_, __) => SizedBox.shrink(),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Limpiar URL'),
                                  content: const Text('¿Descartar esta URL?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                    TextButton(
                                      onPressed: () {
                                        setState(() => photoUrlController.clear());
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Limpiar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              color: Colors.black26,
                              child: const Icon(Icons.close, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
                            icon: _uploadingPhoto
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.camera_alt),
                            label: Text(_uploadingPhoto ? 'Subiendo...' : 'Subir desde galería'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _guardarFoto,
                            child: const Text('Guardar foto de perfil'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Idioma de la aplicación',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Español'),
                    trailing: context.locale.languageCode == 'es'
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary)
                        : null,
                    onTap: () => _changeLanguage(const Locale('es')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('English'),
                    trailing: context.locale.languageCode == 'en'
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary)
                        : null,
                    onTap: () => _changeLanguage(const Locale('en')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Info de estadísticas (solo lectura)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mis estadísticas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('Goles', playerData?['goles'] ?? 0),
                        _statItem('Asistencias', playerData?['asistencias'] ?? 0),
                        _statItem('Partidos', playerData?['partidos'] ?? 0),
                      ],
                    ),
                    const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, dynamic value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
