import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/trainings/domain/entities/training_media_resource.dart';
import 'package:teampulse/features/trainings/domain/entities/training_session.dart';
import 'package:teampulse/features/trainings/domain/repositories/training_repository.dart';
import 'package:teampulse/features/trainings/presentation/providers/training_repository_provider.dart';
import 'package:teampulse/features/trainings/presentation/state/trainings_state.dart';

class TrainingsViewArgs {
  const TrainingsViewArgs({required this.teamId, required this.userId});

  final String teamId;
  final String userId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainingsViewArgs &&
        other.teamId == teamId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(teamId, userId);
}

final trainingsViewModelProvider = AutoDisposeAsyncNotifierProviderFamily<TrainingsViewModel, TrainingsState, TrainingsViewArgs>(
  TrainingsViewModel.new,
);

class TrainingsViewModel extends AutoDisposeFamilyAsyncNotifier<TrainingsState, TrainingsViewArgs> {
  TrainingRepository? _repository;
  TrainingsViewArgs? _args;
  StreamSubscription<List<TrainingSession>>? _sessionsSubscription;
  StreamSubscription<List<TrainingMediaResource>>? _mediaSubscription;

  @override
  FutureOr<TrainingsState> build(TrainingsViewArgs args) async {
    _repository = ref.watch(trainingRepositoryProvider);
    _args = args;

    ref.onDispose(() {
      _sessionsSubscription?.cancel();
      _mediaSubscription?.cancel();
    });

    final isCoach = await _repository!.isCoach(args.userId);

    _sessionsSubscription = _repository!
        .watchTrainings(args.teamId)
        .listen((sessions) => _updateState((current) => current.copyWith(sessions: sessions)), onError: _handleError);

    _mediaSubscription = _repository!
        .watchTrainingMedia(args.teamId)
        .listen((media) => _updateState((current) => current.copyWith(media: media)), onError: _handleError);

    return TrainingsState.initial(teamId: args.teamId, userId: args.userId, isCoach: isCoach);
  }

  Future<void> deleteTraining(String trainingId) async {
    final args = _args;
    if (args == null || trainingId.isEmpty) return;
    await _repository?.deleteTraining(teamId: args.teamId, trainingId: trainingId);
  }

  Future<void> deleteMedia(String mediaId) async {
    final args = _args;
    if (args == null || mediaId.isEmpty) return;
    await _repository?.deleteTrainingMedia(teamId: args.teamId, mediaId: mediaId);
  }

  Future<void> addMedia({
    required String title,
    required TrainingMediaType type,
    required String url,
    String? description,
  }) async {
    final args = _args;
    if (args == null) return;
    await _repository?.addTrainingMedia(
      teamId: args.teamId,
      title: title,
      type: type,
      mediaUrl: url,
      description: description,
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    state = AsyncError(error, stackTrace);
  }

  void _updateState(TrainingsState Function(TrainingsState current) transform) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(transform(current));
  }
}
