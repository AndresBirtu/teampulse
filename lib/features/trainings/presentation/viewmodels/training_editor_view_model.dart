import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/trainings/domain/entities/training_player.dart';
import 'package:teampulse/features/trainings/domain/entities/training_player_status.dart';
import 'package:teampulse/features/trainings/domain/entities/training_session.dart';
import 'package:teampulse/features/trainings/domain/repositories/training_repository.dart';
import 'package:teampulse/features/trainings/presentation/providers/training_repository_provider.dart';
import 'package:teampulse/features/trainings/presentation/state/training_editor_state.dart';

class TrainingEditorArgs {
  const TrainingEditorArgs({required this.teamId, this.trainingId});

  final String teamId;
  final String? trainingId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainingEditorArgs &&
        other.teamId == teamId &&
        other.trainingId == trainingId;
  }

  @override
  int get hashCode => Object.hash(teamId, trainingId);
}

final trainingEditorViewModelProvider = AutoDisposeAsyncNotifierProviderFamily<TrainingEditorViewModel, TrainingEditorState, TrainingEditorArgs>(
  TrainingEditorViewModel.new,
);

class TrainingEditorViewModel extends AutoDisposeFamilyAsyncNotifier<TrainingEditorState, TrainingEditorArgs> {
  TrainingRepository? _repository;

  @override
  FutureOr<TrainingEditorState> build(TrainingEditorArgs args) async {
    _repository = ref.watch(trainingRepositoryProvider);

    final players = await _repository!.loadTeamPlayers(args.teamId);
    final basePlayers = {for (final player in players) player.id: _defaultStatus(player)};

    TrainingSession? session;
    if (args.trainingId != null) {
      session = await _repository!.loadTraining(args.teamId, args.trainingId!);
    }

    final resolvedPlayers = Map<String, TrainingPlayerStatus>.from(basePlayers);
    if (session != null) {
      for (final entry in session.players.entries) {
        resolvedPlayers[entry.key] = entry.value;
      }
    }

    return TrainingEditorState(
      teamId: args.teamId,
      trainingId: args.trainingId,
      date: session?.date ?? DateTime.now(),
      notes: session?.notes ?? '',
      players: resolvedPlayers,
      completed: session?.completed ?? true,
      isSaving: false,
    );
  }

  void updateDate(DateTime date) {
    _updateState((current) => current.copyWith(date: date));
  }

  void updateNotes(String value) {
    _updateState((current) => current.copyWith(notes: value));
  }

  void togglePresence(String playerId) {
    _updatePlayer(playerId, (status) {
      if (status.presence == TrainingPresenceStatus.absent) {
        return status.copyWith(
          presence: TrainingPresenceStatus.present,
          punctuality: TrainingPunctualityStatus.onTime,
        );
      }
      return status.copyWith(
        presence: TrainingPresenceStatus.absent,
        punctuality: TrainingPunctualityStatus.unknown,
      );
    });
  }

  void togglePunctuality(String playerId) {
    _updatePlayer(playerId, (status) {
      if (status.presence == TrainingPresenceStatus.absent) {
        return status.copyWith(
          presence: TrainingPresenceStatus.present,
          punctuality: TrainingPunctualityStatus.onTime,
        );
      }
      final next = status.punctuality == TrainingPunctualityStatus.onTime
          ? TrainingPunctualityStatus.late
          : TrainingPunctualityStatus.onTime;
      return status.copyWith(punctuality: next);
    });
  }

  void cycleMetric(String playerId, TrainingMetricField field) {
    _updatePlayer(playerId, (status) {
      switch (field) {
        case TrainingMetricField.fitness:
          return status.copyWith(fitness: _nextMetric(status.fitness));
        case TrainingMetricField.intensity:
          return status.copyWith(intensity: _nextMetric(status.intensity));
        case TrainingMetricField.technique:
          return status.copyWith(technique: _nextMetric(status.technique));
        case TrainingMetricField.assistance:
          return status.copyWith(assistance: _nextMetric(status.assistance));
        case TrainingMetricField.attitude:
          return status.copyWith(attitude: _nextMetric(status.attitude));
        case TrainingMetricField.injuryRisk:
          return status.copyWith(injuryRisk: _nextRisk(status.injuryRisk));
      }
    });
  }

  void updatePlayerNote(String playerId, String note) {
    _updatePlayer(playerId, (status) => status.copyWith(note: note));
  }

  Future<void> saveTraining() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isSaving: true));
    try {
      final trainingId = await _repository?.saveTraining(
        teamId: current.teamId,
        trainingId: current.trainingId,
        date: current.date,
        notes: current.notes,
        players: current.players,
        completed: current.completed,
      );
      final refreshed = state.value;
      if (refreshed != null) {
        state = AsyncData(
          refreshed.copyWith(
            isSaving: false,
            trainingId: trainingId ?? refreshed.trainingId,
            updateTrainingId: trainingId != null,
          ),
        );
      }
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  TrainingPlayerStatus _defaultStatus(TrainingPlayer player) {
    return TrainingPlayerStatus(
      playerId: player.id,
      name: player.name,
      presence: TrainingPresenceStatus.present,
      punctuality: TrainingPunctualityStatus.onTime,
      fitness: TrainingMetricLevel.high,
      intensity: TrainingMetricLevel.high,
      technique: TrainingMetricLevel.high,
      assistance: TrainingMetricLevel.high,
      attitude: TrainingMetricLevel.high,
      injuryRisk: TrainingRiskLevel.low,
      note: '',
    );
  }

  TrainingMetricLevel _nextMetric(TrainingMetricLevel level) {
    switch (level) {
      case TrainingMetricLevel.low:
        return TrainingMetricLevel.medium;
      case TrainingMetricLevel.medium:
        return TrainingMetricLevel.high;
      case TrainingMetricLevel.high:
        return TrainingMetricLevel.low;
    }
  }

  TrainingRiskLevel _nextRisk(TrainingRiskLevel level) {
    switch (level) {
      case TrainingRiskLevel.low:
        return TrainingRiskLevel.medium;
      case TrainingRiskLevel.medium:
        return TrainingRiskLevel.high;
      case TrainingRiskLevel.high:
        return TrainingRiskLevel.low;
    }
  }

  void _updatePlayer(String playerId, TrainingPlayerStatus Function(TrainingPlayerStatus status) updater) {
    final current = state.value;
    if (current == null) return;
    final player = current.players[playerId];
    if (player == null) return;
    final updatedMap = Map<String, TrainingPlayerStatus>.from(current.players)
      ..[playerId] = updater(player);
    state = AsyncData(current.copyWith(players: updatedMap));
  }

  void _updateState(TrainingEditorState Function(TrainingEditorState current) transform) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(transform(current));
  }
}

enum TrainingMetricField {
  fitness,
  intensity,
  technique,
  assistance,
  attitude,
  injuryRisk,
}
