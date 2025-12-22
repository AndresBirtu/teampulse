import 'package:teampulse/features/trainings/domain/entities/training_player_status.dart';

class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.date,
    required this.notes,
    required this.players,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime? date;
  final String notes;
  final Map<String, TrainingPlayerStatus> players;
  final bool completed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TrainingPlayerStatus? statusFor(String playerId) => players[playerId];

  TrainingSession copyWith({
    String? id,
    DateTime? date,
    bool updateDate = false,
    String? notes,
    Map<String, TrainingPlayerStatus>? players,
    bool? completed,
    DateTime? createdAt,
    bool updateCreatedAt = false,
    DateTime? updatedAt,
    bool updateUpdatedAt = false,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      date: updateDate ? date : (date ?? this.date),
      notes: notes ?? this.notes,
      players: players ?? this.players,
      completed: completed ?? this.completed,
      createdAt: updateCreatedAt ? createdAt : (createdAt ?? this.createdAt),
      updatedAt: updateUpdatedAt ? updatedAt : (updatedAt ?? this.updatedAt),
    );
  }
}
