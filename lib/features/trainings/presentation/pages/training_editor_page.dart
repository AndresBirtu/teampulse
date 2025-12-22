import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/trainings/domain/entities/training_player_status.dart';
import 'package:teampulse/features/trainings/presentation/state/training_editor_state.dart';
import 'package:teampulse/features/trainings/presentation/viewmodels/training_editor_view_model.dart';

class TrainingEditorPage extends ConsumerStatefulWidget {
  const TrainingEditorPage({super.key, required this.teamId, this.trainingId});

  final String teamId;
  final String? trainingId;

  @override
  ConsumerState<TrainingEditorPage> createState() => _TrainingEditorPageState();
}

class _TrainingEditorPageState extends ConsumerState<TrainingEditorPage> {
  late final TextEditingController _notesCtrl;
  bool _syncedNotes = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = TrainingEditorArgs(teamId: widget.teamId, trainingId: widget.trainingId);
    final provider = trainingEditorViewModelProvider(args);
    final asyncState = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    ref.listen(provider, (previous, next) {
      final state = next.asData?.value;
      if (state != null && !_syncedNotes) {
        _notesCtrl.text = state.notes;
        _syncedNotes = true;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.trainingId == null
              ? context.tr('training_create_title')
              : context.tr('training_edit_title'),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          asyncState.maybeWhen(
            data: (state) => TextButton(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      try {
                        await viewModel.saveTraining();
                        if (mounted) Navigator.of(context).pop();
                      } catch (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('training_save_error', args: ['$error']))),
                        );
                      }
                    },
              child: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(context.tr('save'), style: const TextStyle(color: Colors.white)),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (state) {
          if (state.players.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text('${context.tr('date')}: ${state.date.day}/${state.date.month}/${state.date.year}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) viewModel.updateDate(picked);
                    },
                    child: Text(context.tr('change')),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  onChanged: viewModel.updateNotes,
                  decoration: InputDecoration(labelText: context.tr('training_general_notes_label')),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('players'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...state.orderedPlayers.map((status) {
                  return GestureDetector(
                    onTap: () => viewModel.togglePunctuality(status.playerId),
                    onLongPress: () => viewModel.togglePresence(status.playerId),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    status.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Icon(
                                      status.presence == TrainingPresenceStatus.absent
                                          ? Icons.close
                                          : (status.punctuality == TrainingPunctualityStatus.onTime
                                              ? Icons.check_circle
                                              : Icons.access_time),
                                      color: status.presence == TrainingPresenceStatus.absent
                                          ? Colors.grey
                                          : (status.punctuality == TrainingPunctualityStatus.onTime
                                              ? Colors.green
                                              : Colors.orange),
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      status.presence == TrainingPresenceStatus.absent
                                          ? context.tr('training_status_absent')
                                          : (status.punctuality == TrainingPunctualityStatus.onTime
                                              ? context.tr('training_badge_on_time')
                                              : context.tr('training_badge_late')),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.note,
                                    color: status.note.isNotEmpty ? Theme.of(context).primaryColor : Colors.black54,
                                  ),
                                  onPressed: () async {
                                    final text = await _showNoteDialog(initial: status.note);
                                    if (text != null) viewModel.updatePlayerNote(status.playerId, text);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _MetricChip(
                                  label: context.tr('training_metric_physical'),
                                  value: status.fitness,
                                  onTap: () => viewModel.cycleMetric(status.playerId, TrainingMetricField.fitness),
                                ),
                                _MetricChip(
                                  label: context.tr('training_metric_technique'),
                                  value: status.technique,
                                  onTap: () => viewModel.cycleMetric(status.playerId, TrainingMetricField.technique),
                                ),
                                _MetricChip(
                                  label: context.tr('training_metric_attitude'),
                                  value: status.attitude,
                                  onTap: () => viewModel.cycleMetric(status.playerId, TrainingMetricField.attitude),
                                ),
                                _RiskChip(
                                  label: context.tr('training_metric_risk'),
                                  value: status.injuryRisk,
                                  onTap: () => viewModel.cycleMetric(status.playerId, TrainingMetricField.injuryRisk),
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
          );
        },
      ),
    );
  }

  Future<String?> _showNoteDialog({required String initial}) {
    return showDialog<String?>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(text: initial);
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
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TrainingMetricLevel value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor(value);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value == TrainingMetricLevel.low
                  ? Icons.thumb_down
                  : (value == TrainingMetricLevel.medium ? Icons.remove_circle : Icons.thumb_up),
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Color _resolveColor(TrainingMetricLevel level) {
    switch (level) {
      case TrainingMetricLevel.low:
        return Colors.red;
      case TrainingMetricLevel.medium:
        return Colors.orange;
      case TrainingMetricLevel.high:
        return Colors.green;
    }
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TrainingRiskLevel value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor(value);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value == TrainingRiskLevel.low
                  ? Icons.health_and_safety
                  : (value == TrainingRiskLevel.medium ? Icons.report_problem : Icons.warning),
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Color _resolveColor(TrainingRiskLevel level) {
    switch (level) {
      case TrainingRiskLevel.low:
        return Colors.green;
      case TrainingRiskLevel.medium:
        return Colors.orange;
      case TrainingRiskLevel.high:
        return Colors.red;
    }
  }
}
