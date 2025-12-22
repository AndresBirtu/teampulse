import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/matches/domain/entities/match_availability.dart';
import 'package:teampulse/features/matches/domain/entities/match_player.dart';
import 'package:teampulse/features/matches/domain/entities/team_match.dart';
import 'package:teampulse/features/matches/domain/repositories/match_repository.dart';
import 'package:teampulse/features/matches/presentation/providers/match_repository_provider.dart';
import 'package:teampulse/features/matches/presentation/state/match_availability_state.dart';

class MatchAvailabilityViewArgs {
  const MatchAvailabilityViewArgs({
    required this.teamId,
    required this.matchId,
    required this.userId,
    required this.isCoach,
  });

  final String teamId;
  final String matchId;
  final String userId;
  final bool isCoach;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchAvailabilityViewArgs &&
        other.teamId == teamId &&
        other.matchId == matchId &&
        other.userId == userId &&
        other.isCoach == isCoach;
  }

  @override
  int get hashCode => Object.hash(teamId, matchId, userId, isCoach);
}

final matchAvailabilityViewModelProvider = AutoDisposeAsyncNotifierProviderFamily<MatchAvailabilityViewModel, MatchAvailabilityState, MatchAvailabilityViewArgs>(
  MatchAvailabilityViewModel.new,
);

class MatchAvailabilityViewModel extends AutoDisposeFamilyAsyncNotifier<MatchAvailabilityState, MatchAvailabilityViewArgs> {
  MatchRepository? _repository;
  MatchAvailabilityViewArgs? _args;
  StreamSubscription<TeamMatch?>? _matchSubscription;
  StreamSubscription<List<MatchAvailability>>? _availabilitySubscription;
  StreamSubscription<List<MatchPlayer>>? _playersSubscription;

  @override
  FutureOr<MatchAvailabilityState> build(MatchAvailabilityViewArgs args) {
    _repository = ref.watch(matchRepositoryProvider);
    _args = args;

    ref.onDispose(() {
      _matchSubscription?.cancel();
      _availabilitySubscription?.cancel();
      _playersSubscription?.cancel();
    });

    final initialState = MatchAvailabilityState.initial(
      teamId: args.teamId,
      matchId: args.matchId,
      isCoach: args.isCoach,
    );

    _matchSubscription = _repository!
        .watchMatch(args.teamId, args.matchId)
        .listen(_handleMatchUpdate, onError: _handleError);

    _availabilitySubscription = _repository!
        .watchAvailability(args.teamId, args.matchId)
        .listen(_handleAvailabilityUpdate, onError: _handleError);

    _playersSubscription = _repository!
        .watchMatchPlayers(args.teamId)
        .listen(_handlePlayersUpdate, onError: _handleError);

    return initialState;
  }

  Future<void> updateAvailability({
    required MatchAvailabilityStatus status,
    String? reason,
  }) async {
    final args = _args;
    final repository = _repository;
    if (args == null || repository == null || args.userId.isEmpty) return;

    await repository.updateAvailability(
      teamId: args.teamId,
      matchId: args.matchId,
      playerId: args.userId,
      status: status,
      reason: reason,
    );
  }

  Future<void> toggleConvocado(String playerId, bool isConvocado) async {
    final args = _args;
    final repository = _repository;
    if (args == null || repository == null) return;

    await repository.toggleConvocado(
      teamId: args.teamId,
      matchId: args.matchId,
      playerId: playerId,
      isConvocado: isConvocado,
    );
  }

  Future<void> updateCoachMessage(String? message) async {
    final args = _args;
    final repository = _repository;
    if (args == null || repository == null) return;

    await repository.updateCoachMessage(
      teamId: args.teamId,
      matchId: args.matchId,
      message: message,
    );
  }

  void _handleMatchUpdate(TeamMatch? match) {
    _updateState((current) => current.copyWith(match: match, updateMatch: true));
  }

  void _handleAvailabilityUpdate(List<MatchAvailability> availabilities) {
    _updateState((current) => current.copyWith(availabilities: availabilities));
  }

  void _handlePlayersUpdate(List<MatchPlayer> players) {
    _updateState((current) => current.copyWith(players: players));
  }

  void _handleError(Object error, StackTrace stackTrace) {
    state = AsyncError(error, stackTrace);
  }

  void _updateState(MatchAvailabilityState Function(MatchAvailabilityState current) transformer) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(transformer(current));
  }
}
