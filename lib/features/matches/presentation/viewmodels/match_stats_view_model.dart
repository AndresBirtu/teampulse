import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/matches/domain/entities/match_player.dart';
import 'package:teampulse/features/matches/domain/entities/player_match_stat.dart';
import 'package:teampulse/features/matches/domain/entities/team_match.dart';
import 'package:teampulse/features/matches/domain/repositories/match_repository.dart';
import 'package:teampulse/features/matches/presentation/providers/match_repository_provider.dart';
import 'package:teampulse/features/matches/presentation/state/match_stats_state.dart';

class MatchStatsViewArgs {
  const MatchStatsViewArgs({
    required this.teamId,
    required this.matchId,
    this.matchDurationMinutes = 90,
  });

  final String teamId;
  final String matchId;
  final int matchDurationMinutes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchStatsViewArgs &&
        other.teamId == teamId &&
        other.matchId == matchId &&
        other.matchDurationMinutes == matchDurationMinutes;
  }

  @override
  int get hashCode => Object.hash(teamId, matchId, matchDurationMinutes);
}

final matchStatsViewModelProvider = AutoDisposeAsyncNotifierProviderFamily<MatchStatsViewModel, MatchStatsState, MatchStatsViewArgs>(
  MatchStatsViewModel.new,
);

class MatchStatsViewModel extends AutoDisposeFamilyAsyncNotifier<MatchStatsState, MatchStatsViewArgs> {
  MatchRepository? _repository;
  MatchStatsViewArgs? _args;
  StreamSubscription<TeamMatch?>? _matchSubscription;
  StreamSubscription<List<PlayerMatchStat>>? _statsSubscription;
  StreamSubscription<List<MatchPlayer>>? _playersSubscription;

  @override
  FutureOr<MatchStatsState> build(MatchStatsViewArgs args) async {
    _repository = ref.watch(matchRepositoryProvider);
    _args = args;

    ref.onDispose(() {
      _matchSubscription?.cancel();
      _statsSubscription?.cancel();
      _playersSubscription?.cancel();
    });

    String? coachId;
    try {
      coachId = await _repository!.loadTeamCoachId(args.teamId);
    } catch (_) {
      coachId = null;
    }

    final initialState = MatchStatsState.initial(
      teamId: args.teamId,
      matchId: args.matchId,
      matchDuration: args.matchDurationMinutes,
      coachId: coachId,
    );

    _matchSubscription = _repository!
        .watchMatch(args.teamId, args.matchId)
        .listen(_handleMatchUpdate, onError: _handleError);

    _statsSubscription = _repository!
        .watchMatchStats(args.teamId, args.matchId)
        .listen(_handleStatsUpdate, onError: _handleError);

    _playersSubscription = _repository!
        .watchMatchPlayers(args.teamId)
        .listen(_handlePlayersUpdate, onError: _handleError);

    return initialState;
  }

  Future<void> toggleConvocado(String playerId, bool isConvocado) async {
    final args = _args;
    final repository = _repository;
    if (args == null || repository == null) return;

    final updates = <String, dynamic>{'convocado': isConvocado};
    if (!isConvocado) {
      updates['minutos'] = 0;
      updates['titular'] = false;
    }

    await repository.updatePlayerStats(
      teamId: args.teamId,
      matchId: args.matchId,
      playerId: playerId,
      updates: updates,
    );
  }

  Future<void> toggleStarter(String playerId, bool isStarter) async {
    final args = _args;
    final repository = _repository;
    final current = state.value?.statById(playerId);
    if (args == null || repository == null) return;

    final updates = <String, dynamic>{'titular': isStarter};
    if (isStarter && (current?.minutes ?? 0) == 0) {
      updates['minutos'] = state.value?.matchDuration ?? args.matchDurationMinutes;
    }

    await repository.updatePlayerStats(
      teamId: args.teamId,
      matchId: args.matchId,
      playerId: playerId,
      updates: updates,
    );
  }

  Future<void> setMinutes(String playerId, int minutes) async {
    final args = _args;
    final repository = _repository;
    if (args == null || repository == null) return;
    final duration = state.value?.matchDuration ?? args.matchDurationMinutes;
    final clamped = minutes.clamp(0, duration);

    await repository.updatePlayerStats(
      teamId: args.teamId,
      matchId: args.matchId,
      playerId: playerId,
      updates: {'minutos': clamped},
    );
  }

  Future<void> adjustGoals(String playerId, int delta) => _adjustIntStat(
        playerId: playerId,
        fieldName: 'goles',
        extractor: (stat) => stat.goals,
        delta: delta,
      );

  Future<void> adjustAssists(String playerId, int delta) => _adjustIntStat(
        playerId: playerId,
        fieldName: 'asistencias',
        extractor: (stat) => stat.assists,
        delta: delta,
      );

  Future<void> adjustYellowCards(String playerId, int delta) => _adjustIntStat(
        playerId: playerId,
        fieldName: 'amarillas',
        extractor: (stat) => stat.yellowCards,
        delta: delta,
      );

  Future<void> addRedCard(String playerId) => _modifyRedCards(playerId, 1);

  Future<void> removeRedCard(String playerId) => _modifyRedCards(playerId, -1);

  Future<void> saveChanges() async {
    final args = _args;
    final repository = _repository;
    if (args == null || repository == null) return;

    _setSaving(true);
    try {
      await repository.ensureStatsAppliedIfNeeded(teamId: args.teamId, matchId: args.matchId);
    } finally {
      _setSaving(false);
    }
  }

  Future<void> applyStats() async {
    final args = _args;
    final repository = _repository;
    if (args == null || repository == null) return;

    _setApplying(true);
    try {
      await repository.applyStatsToPlayers(teamId: args.teamId, matchId: args.matchId);
    } finally {
      _setApplying(false);
    }
  }

  Future<void> forceReapplyStats() async {
    final args = _args;
    final repository = _repository;
    if (args == null || repository == null) return;

    _setApplying(true);
    try {
      await repository.revertStatsFromPlayers(teamId: args.teamId, matchId: args.matchId);
      await repository.applyStatsToPlayers(teamId: args.teamId, matchId: args.matchId);
    } finally {
      _setApplying(false);
    }
  }

  void _handleMatchUpdate(TeamMatch? match) {
    _updateState((current) => current.copyWith(match: match, updateMatch: true));
  }

  void _handleStatsUpdate(List<PlayerMatchStat> stats) {
    _updateState((current) => current.copyWith(stats: stats));
  }

  void _handlePlayersUpdate(List<MatchPlayer> players) {
    _updateState((current) => current.copyWith(players: players));
  }

  Future<void> _adjustIntStat({
    required String playerId,
    required String fieldName,
    required int Function(PlayerMatchStat stat) extractor,
    required int delta,
  }) async {
    final args = _args;
    final repository = _repository;
    if (args == null || repository == null) return;

    final current = state.value?.statById(playerId);
    final currentValue = current == null ? 0 : extractor(current);
    final nextValue = (currentValue + delta).clamp(0, 999);

    await repository.updatePlayerStats(
      teamId: args.teamId,
      matchId: args.matchId,
      playerId: playerId,
      updates: {fieldName: nextValue},
    );
  }

  Future<void> _modifyRedCards(String playerId, int delta) async {
    final args = _args;
    final repository = _repository;
    if (args == null || repository == null) return;

    final stat = state.value?.statById(playerId);
    final currentValue = stat?.redCards ?? 0;
    final nextValue = (currentValue + delta).clamp(0, 999);
    if (delta > 0) {
      await repository.registerRedCardSanction(
        teamId: args.teamId,
        matchId: args.matchId,
        playerId: playerId,
        playerName: stat?.playerName ?? 'Jugador',
      );
    } else {
      await repository.removeRedCardSanction(
        teamId: args.teamId,
        matchId: args.matchId,
        playerId: playerId,
      );
    }

    await repository.updatePlayerStats(
      teamId: args.teamId,
      matchId: args.matchId,
      playerId: playerId,
      updates: {'rojas': nextValue},
    );
  }

  void _setSaving(bool value) {
    _updateState((current) => current.copyWith(isSaving: value));
  }

  void _setApplying(bool value) {
    _updateState((current) => current.copyWith(isApplying: value));
  }

  void _handleError(Object error, StackTrace stackTrace) {
    state = AsyncError(error, stackTrace);
  }

  void _updateState(MatchStatsState Function(MatchStatsState current) transformer) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(transformer(current));
  }
}
