import 'package:teampulse/features/trainings/domain/entities/training_media_resource.dart';
import 'package:teampulse/features/trainings/domain/entities/training_player.dart';
import 'package:teampulse/features/trainings/domain/entities/training_player_status.dart';
import 'package:teampulse/features/trainings/domain/entities/training_session.dart';

abstract class TrainingRepository {
  Stream<List<TrainingSession>> watchTrainings(String teamId);
  Stream<List<TrainingMediaResource>> watchTrainingMedia(String teamId);
  Future<TrainingSession?> loadTraining(String teamId, String trainingId);
  Future<List<TrainingPlayer>> loadTeamPlayers(String teamId);
  Future<bool> isCoach(String userId);

  Future<String> saveTraining({
    required String teamId,
    String? trainingId,
    required DateTime date,
    required String notes,
    required Map<String, TrainingPlayerStatus> players,
    required bool completed,
  });

  Future<void> deleteTraining({
    required String teamId,
    required String trainingId,
  });

  Future<void> addTrainingMedia({
    required String teamId,
    required String title,
    required TrainingMediaType type,
    required String mediaUrl,
    String? description,
  });

  Future<void> deleteTrainingMedia({
    required String teamId,
    required String mediaId,
  });
}
