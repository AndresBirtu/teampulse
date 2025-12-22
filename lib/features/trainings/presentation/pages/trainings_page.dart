import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:teampulse/core/providers/firebase_providers.dart';
import 'package:teampulse/features/trainings/domain/entities/training_media_resource.dart';
import 'package:teampulse/features/trainings/domain/entities/training_player_status.dart';
import 'package:teampulse/features/trainings/domain/entities/training_session.dart';
import 'package:teampulse/features/trainings/presentation/pages/training_editor_page.dart';
import 'package:teampulse/features/trainings/presentation/viewmodels/trainings_view_model.dart';

class TrainingsPage extends ConsumerStatefulWidget {
  const TrainingsPage({required this.teamId, super.key});

  final String teamId;

  @override
  ConsumerState<TrainingsPage> createState() => _TrainingsPageState();
}

class _TrainingsPageState extends ConsumerState<TrainingsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
    final args = TrainingsViewArgs(teamId: widget.teamId, userId: userId);
    final provider = trainingsViewModelProvider(args);
    final asyncState = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    final floatingActionButton = asyncState.maybeWhen(
      data: (state) {
        if (!state.isCoach) return null;
        if (_tabController.index == 0) {
          return FloatingActionButton.extended(
            backgroundColor: Theme.of(context).primaryColor,
            icon: const Icon(Icons.add),
            label: Text(context.tr('add_training')),
            onPressed: () => _openTrainingEditor(),
          );
        }
        return FloatingActionButton.extended(
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.video_library),
          label: Text(context.tr('training_media_new_resource_button')),
          onPressed: () => _openMediaDialog(viewModel),
        );
      },
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('trainings')),
        backgroundColor: Theme.of(context).primaryColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: context.tr('training_tab_sessions')),
            Tab(text: context.tr('training_tab_material')),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error cargando entrenamientos: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _TrainingsSessionsTab(
                sessions: state.sessions,
                isCoach: state.isCoach,
                userId: state.userId,
                formatDate: _formatTrainingDate,
                statusLabel: (status) => _playerStatusLabel(context, status),
                onCoachEdit: (session) => _openTrainingEditor(trainingId: session.id),
                onPlayerInspect: (session, status) => _showPlayerTrainingDetail(
                  session: session,
                  playerStatus: status,
                ),
              ),
              _TrainingMediaTab(
                media: state.media,
                isCoach: state.isCoach,
                onOpen: _openMediaResource,
                onShowImage: _showImage,
                onDelete: (mediaId) async {
                  try {
                    await viewModel.deleteMedia(mediaId);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('training_media_deleted'))),
                    );
                  } catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('training_media_delete_error', args: ['$error']))),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openTrainingEditor({String? trainingId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingEditorPage(teamId: widget.teamId, trainingId: trainingId),
      ),
    );
  }

  void _showPlayerTrainingDetail({
    required TrainingSession session,
    required TrainingPlayerStatus? playerStatus,
  }) {
    final formatted = _formatTrainingDate(session.date);
    final generalNote = session.notes.trim();
    final personalNote = playerStatus?.note.trim() ?? '';
    final statusLabel = _playerStatusLabel(context, playerStatus);

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
              Text(formatted, style: const TextStyle(fontSize: 15)),
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

  String _formatTrainingDate(DateTime? date) {
    if (date == null) return context.tr('training_no_date');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _playerStatusLabel(BuildContext context, TrainingPlayerStatus? status) {
    if (status == null) return context.tr('training_status_not_recorded');
    if (status.presence == TrainingPresenceStatus.absent) {
      return context.tr('training_status_absent');
    }
    if (status.punctuality == TrainingPunctualityStatus.late) {
      return context.tr('training_status_present_late');
    }
    if (status.punctuality == TrainingPunctualityStatus.onTime) {
      return context.tr('training_status_present_on_time');
    }
    return context.tr('training_status_not_recorded');
  }

  Future<void> _openMediaResource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('training_media_invalid_url'))),
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('training_media_open_failed'))),
      );
    }
  }

  void _showImage(String url, String title) {
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

  void _openMediaDialog(TrainingsViewModel viewModel) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    var type = TrainingMediaType.video;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
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
                    DropdownButtonFormField<TrainingMediaType>(
                      value: type,
                      decoration: InputDecoration(labelText: context.tr('training_media_field_type')),
                      items: [
                        DropdownMenuItem(
                          value: TrainingMediaType.video,
                          child: Text(context.tr('training_media_option_video')),
                        ),
                        DropdownMenuItem(
                          value: TrainingMediaType.photo,
                          child: Text(context.tr('training_media_option_photo')),
                        ),
                        DropdownMenuItem(
                          value: TrainingMediaType.document,
                          child: Text(context.tr('training_media_option_document')),
                        ),
                      ],
                      onChanged: (value) => setModalState(() => type = value ?? TrainingMediaType.video),
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
                          try {
                            await viewModel.addMedia(
                              title: title,
                              type: type,
                              url: url,
                              description: descCtrl.text.trim(),
                            );
                            if (!mounted) return;
                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('training_media_saved'))),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('training_media_save_error', args: ['$error']))),
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
}

class _TrainingsSessionsTab extends StatelessWidget {
  const _TrainingsSessionsTab({
    required this.sessions,
    required this.isCoach,
    required this.userId,
    required this.formatDate,
    required this.statusLabel,
    required this.onCoachEdit,
    required this.onPlayerInspect,
  });

  final List<TrainingSession> sessions;
  final bool isCoach;
  final String userId;
  final String Function(DateTime? date) formatDate;
  final String Function(TrainingPlayerStatus? status) statusLabel;
  final void Function(TrainingSession session) onCoachEdit;
  final void Function(TrainingSession session, TrainingPlayerStatus? status) onPlayerInspect;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.tr('training_empty_state'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final formatted = formatDate(session.date);
        final notes = session.notes.trim();
        final playerStatus = session.statusFor(userId);
        final personalNote = playerStatus?.note.trim() ?? '';
        final status = statusLabel(playerStatus);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(
              context.tr('training_card_title', args: [formatted]),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: isCoach
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
                          args: [notes.isNotEmpty ? notes : context.tr('training_general_note_placeholder')],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        personalNote.isNotEmpty
                            ? context.tr('training_personal_note_line', args: [personalNote])
                            : context.tr('training_personal_note_placeholder'),
                      ),
                      const SizedBox(height: 4),
                      Text(context.tr('training_status_line', args: [status])),
                    ],
                  ),
            trailing: Icon(
              isCoach ? Icons.chevron_right : Icons.info_outline,
              color: Theme.of(context).primaryColor,
            ),
            onTap: () => isCoach
                ? onCoachEdit(session)
                : onPlayerInspect(session, playerStatus),
          ),
        );
      },
    );
  }
}

class _TrainingMediaTab extends StatelessWidget {
  const _TrainingMediaTab({
    required this.media,
    required this.isCoach,
    required this.onOpen,
    required this.onShowImage,
    required this.onDelete,
  });

  final List<TrainingMediaResource> media;
  final bool isCoach;
  final Future<void> Function(String url) onOpen;
  final void Function(String url, String title) onShowImage;
  final Future<void> Function(String mediaId)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.tr('training_media_empty_state'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final resource = media[index];
        final createdAt = resource.createdAt;
        final dateStr = createdAt != null
            ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
            : '';
        final isPhoto = resource.isPhoto;
        final isVideo = resource.isVideo;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPhoto && resource.mediaUrl.isNotEmpty)
                GestureDetector(
                  onTap: () => onShowImage(resource.mediaUrl, resource.title),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Image.network(
                      resource.mediaUrl,
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
                      isVideo ? Icons.play_circle_fill : Icons.insert_drive_file,
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
                    Text(resource.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (resource.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(resource.description, style: const TextStyle(color: Colors.black87)),
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
                    if (resource.mediaUrl.isNotEmpty)
                      TextButton.icon(
                        icon: Icon(isPhoto ? Icons.fullscreen : Icons.open_in_new),
                        label: Text(
                          isPhoto
                              ? context.tr('training_media_view_image')
                              : context.tr('training_media_open_resource'),
                        ),
                        onPressed: () => isPhoto
                            ? onShowImage(resource.mediaUrl, resource.title)
                            : onOpen(resource.mediaUrl),
                      ),
                    const Spacer(),
                    if (isCoach && onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete!(resource.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
