import 'package:teampulse/features/trainings/domain/entities/training_player_status.dart';

class TrainingEditorState {
  const TrainingEditorState({
    required this.teamId,
    required this.trainingId,
    required this.date,
    required this.notes,
    required this.players,
    required this.completed,
    required this.isSaving,
  });

  final String teamId;
  final String? trainingId;
  final DateTime date;
  final String notes;
  final Map<String, TrainingPlayerStatus> players;
  final bool completed;
  final bool isSaving;

  factory TrainingEditorState.initial({
    required String teamId,
    required String? trainingId,
    DateTime? date,
  }) {
    return TrainingEditorState(
      teamId: teamId,
      trainingId: trainingId,
      date: date ?? DateTime.now(),
      notes: '',
      players: const {},
      completed: true,
      isSaving: false,
    );
  }

  List<TrainingPlayerStatus> get orderedPlayers {
    final list = players.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  TrainingPlayerStatus? playerById(String id) => players[id];

  TrainingEditorState copyWith({
    String? trainingId,
    bool updateTrainingId = false,
    DateTime? date,
    String? notes,
    Map<String, TrainingPlayerStatus>? players,
    bool? completed,
    bool? isSaving,
  }) {
    return TrainingEditorState(
      teamId: teamId,
      trainingId: updateTrainingId ? trainingId : (trainingId ?? this.trainingId),
      date: date ?? this.date,
      notes: notes ?? this.notes,
      players: players ?? this.players,
      completed: completed ?? this.completed,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
