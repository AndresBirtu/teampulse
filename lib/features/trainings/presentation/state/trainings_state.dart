import 'package:teampulse/features/trainings/domain/entities/training_media_resource.dart';
import 'package:teampulse/features/trainings/domain/entities/training_player_status.dart';
import 'package:teampulse/features/trainings/domain/entities/training_session.dart';

class TrainingsState {
  const TrainingsState({
    required this.teamId,
    required this.userId,
    required this.isCoach,
    required this.sessions,
    required this.media,
  });

  final String teamId;
  final String userId;
  final bool isCoach;
  final List<TrainingSession> sessions;
  final List<TrainingMediaResource> media;

  factory TrainingsState.initial({
    required String teamId,
    required String userId,
    required bool isCoach,
  }) {
    return TrainingsState(
      teamId: teamId,
      userId: userId,
      isCoach: isCoach,
      sessions: const [],
      media: const [],
    );
  }

  bool get hasSessions => sessions.isNotEmpty;
  bool get hasMedia => media.isNotEmpty;

  TrainingPlayerStatus? userStatusFor(TrainingSession session) {
    if (userId.isEmpty) return null;
    return session.statusFor(userId);
  }

  TrainingsState copyWith({
    String? teamId,
    String? userId,
    bool? isCoach,
    List<TrainingSession>? sessions,
    List<TrainingMediaResource>? media,
  }) {
    return TrainingsState(
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      isCoach: isCoach ?? this.isCoach,
      sessions: sessions ?? this.sessions,
      media: media ?? this.media,
    );
  }
}
