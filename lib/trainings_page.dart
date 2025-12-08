import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class TrainingsPage extends StatefulWidget {
  final String teamId;
  const TrainingsPage({super.key, required this.teamId});

  @override
  State<TrainingsPage> createState() => _TrainingsPageState();
}

class _TrainingsPageState extends State<TrainingsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isCoach = false;
  bool _roleLoaded = false;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _currentUid = null;
        _roleLoaded = true;
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = (doc.data()?['role'] as String?)?.toLowerCase() ?? '';
      if (!mounted) return;
      setState(() {
        _currentUid = uid;
        _isCoach = role == 'entrenador' || role == 'coach';
        _roleLoaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentUid = uid;
          _roleLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openNewTraining() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTrainingPage(teamId: widget.teamId)),
    );
  }

  String _formatTrainingDate(DateTime? date) {
    if (date == null) return context.tr('training_no_date');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _playerStatusLabel(Map<String, dynamic>? playerData) {
    if (playerData == null) return context.tr('training_status_not_recorded');
    final presence = (playerData['presence'] ?? '').toString();
    final punctuality = (playerData['punctuality'] ?? '').toString();
    if (presence == 'absent') return context.tr('training_status_absent');
    if (presence == 'present' && punctuality == 'late') {
      return context.tr('training_status_present_late');
    }
    if (presence == 'present') return context.tr('training_status_present_on_time');
    return context.tr('training_status_not_recorded');
  }

  void _showPlayerTrainingDetail({
    required String scheduledText,
    required String generalNote,
    required String personalNote,
    required String statusLabel,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('training_modal_session_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(scheduledText, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 18),
              Text(
                context.tr('training_modal_general_note_title'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                generalNote.isNotEmpty
                    ? generalNote
                    : context.tr('training_modal_general_note_placeholder'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('training_modal_personal_note_title'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                personalNote.isNotEmpty
                    ? personalNote
                    : context.tr('training_modal_personal_note_placeholder'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('training_modal_status_title'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(statusLabel, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMediaResource(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('trainingMedia')
          .doc(id)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('training_media_deleted'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('training_media_delete_error', args: ['$e']))),
      );
    }
  }

  Future<bool> _saveMediaResource({
    required String title,
    required String type,
    required String url,
    required String description,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('trainingMedia')
          .add({
        'title': title,
        'description': description,
        'mediaUrl': url,
        'type': type,
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('training_media_save_error', args: ['$e']))),
        );
      }
      return false;
    }
  }

  void _openMediaDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String type = 'video';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('training_media_new_resource'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(labelText: context.tr('training_media_field_title')),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: context.tr('training_media_field_description')),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: InputDecoration(labelText: context.tr('training_media_field_type')),
                      items: [
                        DropdownMenuItem(value: 'video', child: Text(context.tr('training_media_option_video'))),
                        DropdownMenuItem(value: 'photo', child: Text(context.tr('training_media_option_photo'))),
                        DropdownMenuItem(value: 'document', child: Text(context.tr('training_media_option_document'))),
                      ],
                      onChanged: (value) => setModalState(() => type = value ?? 'video'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlCtrl,
                      decoration: InputDecoration(labelText: context.tr('training_media_field_url')),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(context.tr('training_media_save_button')),
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          final url = urlCtrl.text.trim();
                          if (title.isEmpty || url.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('training_media_validation_title_url'))),
                            );
                            return;
                          }
                          final success = await _saveMediaResource(
                            title: title,
                            type: type,
                            url: url,
                            description: descCtrl.text.trim(),
                          );
                          if (success && mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('training_media_saved'))),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrainingsTab() {
    final trainingsStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('trainings')
        .orderBy('date', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: trainingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              context.tr('training_empty_state'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp?)?.toDate();
            final formatted = _formatTrainingDate(date);
            final notes = (data['notes'] ?? '').toString().trim();
            Map<String, dynamic>? playerData;
            if (!_isCoach && _currentUid != null) {
              final playersMap = data['players'];
              if (playersMap is Map<String, dynamic>) {
                final rawEntry = playersMap[_currentUid];
                if (rawEntry is Map<String, dynamic>) {
                  playerData = rawEntry;
                }
              }
            }
            final personalNote = playerData?['note']?.toString().trim() ?? '';
            final statusLabel = _playerStatusLabel(playerData);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  context.tr('training_card_title', args: [formatted]),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: _isCoach
                    ? Text(
                        notes.isEmpty ? context.tr('training_no_general_notes') : notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(context.tr('training_programmed_line', args: [formatted])),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(
                              'training_general_note_line',
                              args: [
                                notes.isNotEmpty
                                    ? notes
                                    : context.tr('training_general_note_placeholder'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            personalNote.isNotEmpty
                                ? context.tr('training_personal_note_line', args: [personalNote])
                                : context.tr('training_personal_note_placeholder'),
                          ),
                          const SizedBox(height: 4),
                          Text(context.tr('training_status_line', args: [statusLabel])),
                        ],
                      ),
                trailing: Icon(
                  _isCoach ? Icons.chevron_right : Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                onTap: () {
                  if (_isCoach) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditTrainingPage(teamId: widget.teamId, trainingId: d.id),
                      ),
                    );
                  } else {
                    _showPlayerTrainingDetail(
                      scheduledText: formatted,
                      generalNote: notes,
                      personalNote: personalNote,
                      statusLabel: statusLabel,
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('trainings')),
        backgroundColor: Theme.of(context).primaryColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: context.tr('training_tab_sessions')),
            Tab(text: context.tr('training_tab_material')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrainingsTab(),
          _MediaLibraryTab(
            teamId: widget.teamId,
            isCoach: _isCoach,
            onDelete: _isCoach ? _deleteMediaResource : null,
          ),
        ],
      ),
      floatingActionButton: (!_roleLoaded || !_isCoach)
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor,
              icon: Icon(_tabController.index == 0 ? Icons.add : Icons.video_library),
              label: Text(_tabController.index == 0 ? context.tr('add_training') : context.tr('training_media_new_resource_button')),
              onPressed: _tabController.index == 0 ? _openNewTraining : _openMediaDialog,
            ),
    );
  }
}

class _MediaLibraryTab extends StatelessWidget {
  final String teamId;
  final bool isCoach;
  final Future<void> Function(String mediaId)? onDelete;

  const _MediaLibraryTab({
    required this.teamId,
    required this.isCoach,
    this.onDelete,
  });

  Future<void> _launchMedia(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('training_media_invalid_url'))),
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('training_media_open_failed'))),
      );
    }
  }

  void _showImage(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(context.tr('training_media_image_load_error')),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('close')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('trainingMedia')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.tr('training_media_empty_state'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title']?.toString() ?? context.tr('training_media_default_title');
            final description = data['description']?.toString() ?? '';
            final mediaUrl = data['mediaUrl']?.toString() ?? '';
            final type = data['type']?.toString() ?? 'video';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final dateStr = createdAt != null
                ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                : '';

            final isPhoto = type == 'photo';
            final isVideo = type == 'video';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPhoto && mediaUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showImage(context, mediaUrl, title),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: Image.network(
                          mediaUrl,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 190,
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: Text(context.tr('training_media_image_error')),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: Center(
                        child: Icon(
                          isVideo
                              ? Icons.play_circle_fill
                              : Icons.insert_drive_file,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(description, style: const TextStyle(color: Colors.black87)),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isVideo
                                        ? Icons.videocam
                                        : (isPhoto ? Icons.photo : Icons.description),
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isVideo
                                        ? context.tr('training_media_type_video')
                                        : (isPhoto
                                            ? context.tr('training_media_type_photo')
                                            : context.tr('training_media_type_document')),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (dateStr.isNotEmpty)
                              Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Row(
                      children: [
                        if (mediaUrl.isNotEmpty)
                          TextButton.icon(
                            icon: Icon(isPhoto ? Icons.fullscreen : Icons.open_in_new),
                            label: Text(
                              isPhoto
                                  ? context.tr('training_media_view_image')
                                  : context.tr('training_media_open_resource'),
                            ),
                            onPressed: () => isPhoto
                                ? _showImage(context, mediaUrl, title)
                                : _launchMedia(context, mediaUrl),
                          ),
                        const Spacer(),
                        if (isCoach)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: onDelete == null ? null : () => onDelete!(doc.id),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class EditTrainingPage extends StatefulWidget {
  final String teamId;
  final String? trainingId;

  const EditTrainingPage({super.key, required this.teamId, this.trainingId});

  @override
  State<EditTrainingPage> createState() => _EditTrainingPageState();
}

class _EditTrainingPageState extends State<EditTrainingPage> {
  DateTime _date = DateTime.now();
  final TextEditingController _notesCtrl = TextEditingController();
  Map<String, dynamic> _playersState = {}; // playerId -> {presence, punctuality, fitness, name}
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    if (widget.trainingId != null) _loadExisting();
  }

  Future<void> _loadPlayers() async {
    final snap = await FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('players').get();
    final map = <String, dynamic>{};
    for (var doc in snap.docs) {
      final d = doc.data();
      map[doc.id] = {
        'name': d['name'] ?? context.tr('player'),
        // default: assume present and on-time for fast marking
        'presence': 'present',
        'punctuality': 'on-time',
        'fitness': 3,
        'note': '',
        // extended metrics: 1 (bad/red), 2 (medium/orange), 3 (good/green)
        'intensity': 3,
        'technique': 3,
        'assistance': 3,
        'attitude': 3,
        'injuryRisk': 1,
      };
    }
    setState(() => _playersState = map);
  }

  Future<void> _loadExisting() async {
    final doc = await FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('trainings').doc(widget.trainingId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    setState(() {
      _date = (data['date'] as Timestamp).toDate();
      _notesCtrl.text = data['notes'] ?? '';
      final players = data['players'] as Map<String, dynamic>? ?? {};
      for (var e in players.entries) {
        _playersState[e.key] = {
          'name': (players[e.key]['name'] ?? _playersState[e.key]?['name']) ?? context.tr('player'),
          'presence': players[e.key]['presence'] ?? 'absent',
          'punctuality': players[e.key]['punctuality'] ?? 'on-time',
          'fitness': players[e.key]['fitness'] ?? 3,
        };
      }
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final playersMap = <String, dynamic>{};
      _playersState.forEach((k, v) {
        playersMap[k] = {
          'name': v['name'],
          'presence': v['presence'],
          'punctuality': v['punctuality'],
          'fitness': v['fitness'],
          'note': v['note'] ?? '',
        };
      });

      final data = {
        'date': Timestamp.fromDate(_date),
        'notes': _notesCtrl.text.trim(),
        'players': playersMap,
        'completed': true, // mark training as completed when saved
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final col = FirebaseFirestore.instance.collection('teams').doc(widget.teamId).collection('trainings');
      if (widget.trainingId == null) {
        await col.add({...data, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await col.doc(widget.trainingId).set(data, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('training_save_error', args: ['$e']))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Widget _metricChip(
    BuildContext context,
    Map<String, dynamic> p,
    String metricField,
    String label,
    int value,
  ) {
    int v = (p[metricField] ?? value) as int;
    final isRisk = metricField == 'injuryRisk';

    Color chipColor;
    if (isRisk) {
      if (v <= 1) {
        chipColor = Colors.green;
      } else if (v == 2) {
        chipColor = Colors.orange;
      } else {
        chipColor = Colors.red;
      }
    } else {
      if (v <= 1) {
        chipColor = Colors.red;
      } else if (v == 2) {
        chipColor = Colors.orange;
      } else {
        chipColor = Colors.green;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          int cur = (p[metricField] ?? value) as int;
          cur = (cur % 3) + 1;
          p[metricField] = cur;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipColor.withOpacity(0.9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRisk
                  ? (v == 1 ? Icons.health_and_safety : (v == 2 ? Icons.report_problem : Icons.warning))
                  : (v == 1 ? Icons.thumb_down : (v == 2 ? Icons.remove_circle : Icons.thumb_up)),
              size: 16,
              color: chipColor,
            ),
            const SizedBox(width: 6),
            Text('$label', style: TextStyle(color: chipColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.trainingId == null
              ? context.tr('training_create_title')
              : context.tr('training_edit_title'),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(context.tr('save'), style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _playersState.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text('${context.tr('date')}: ${_date.day}/${_date.month}/${_date.year}'),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      child: Text(context.tr('change')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: context.tr('training_general_notes_label')),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('players'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._playersState.entries.map((e) {
                    final p = e.value as Map<String, dynamic>;
                    final presence = (p['presence'] ?? 'present') as String;
                    final punctuality = (p['punctuality'] ?? 'on-time') as String;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if ((p['presence'] ?? 'present') == 'absent') {
                            p['presence'] = 'present';
                            p['punctuality'] = 'on-time';
                          } else {
                            p['punctuality'] = (p['punctuality'] == 'on-time') ? 'late' : 'on-time';
                          }
                        });
                      },
                      onDoubleTap: () {
                        setState(() {
                          if ((p['presence'] ?? 'present') == 'absent') {
                            p['presence'] = 'present';
                            p['punctuality'] = 'on-time';
                          } else {
                            p['presence'] = 'absent';
                            p['punctuality'] = 'absent';
                          }
                        });
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fila superior: nombre, estado, nota
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p['name'] ?? context.tr('player'),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          presence == 'absent'
                                              ? Icons.close
                                              : (punctuality == 'on-time' ? Icons.check_circle : Icons.access_time),
                                          color: presence == 'absent'
                                              ? Colors.grey
                                              : (punctuality == 'on-time' ? Colors.green : Colors.orange),
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          presence == 'absent'
                                              ? context.tr('training_status_absent')
                                              : (punctuality == 'on-time'
                                                  ? context.tr('training_badge_on_time')
                                                  : context.tr('training_badge_late')),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.note, color: (p['note'] ?? '').toString().isNotEmpty ? Theme.of(context).primaryColor : Colors.black54),
                                    onPressed: () async {
                                      final text = await showDialog<String?>(
                                        context: context,
                                        builder: (ctx) {
                                          final ctrl = TextEditingController(text: p['note'] ?? '');
                                          return AlertDialog(
                                            title: Text(context.tr('training_player_note_title')),
                                            content: TextField(
                                              controller: ctrl,
                                              maxLines: 4,
                                              decoration: InputDecoration(
                                                hintText: context.tr('training_player_note_hint'),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(null),
                                                child: Text(context.tr('cancel')),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
                                                child: Text(context.tr('save')),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (text != null) setState(() => p['note'] = text);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Métricas: Físico, Técnica, Actitud, Riesgo
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _metricChip(
                                    context,
                                    p,
                                    'fitness',
                                    context.tr('training_metric_physical'),
                                    p['fitness'] ?? 3,
                                  ),
                                  _metricChip(
                                    context,
                                    p,
                                    'technique',
                                    context.tr('training_metric_technique'),
                                    p['technique'] ?? 3,
                                  ),
                                  _metricChip(
                                    context,
                                    p,
                                    'attitude',
                                    context.tr('training_metric_attitude'),
                                    p['attitude'] ?? 3,
                                  ),
                                  _metricChip(
                                    context,
                                    p,
                                    'injuryRisk',
                                    context.tr('training_metric_risk'),
                                    p['injuryRisk'] ?? 1,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
