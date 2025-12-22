import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/matches/domain/entities/team_match.dart';
import 'package:teampulse/features/matches/domain/repositories/match_repository.dart';
import 'package:teampulse/features/matches/presentation/state/matches_state.dart';
import 'package:teampulse/features/matches/presentation/providers/match_repository_provider.dart';

class MatchesViewArgs {
  const MatchesViewArgs({required this.teamId, required this.userId});

  final String teamId;
  final String userId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchesViewArgs &&
        other.teamId == teamId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(teamId, userId);
}

final matchesViewModelProvider = AutoDisposeAsyncNotifierProviderFamily<MatchesViewModel, MatchesState, MatchesViewArgs>(
  MatchesViewModel.new,
);

class MatchesViewModel extends AutoDisposeFamilyAsyncNotifier<MatchesState, MatchesViewArgs> {
  MatchRepository? _repository;
  MatchesViewArgs? _args;
  StreamSubscription<List<TeamMatch>>? _matchesSubscription;

  @override
  Future<MatchesState> build(MatchesViewArgs args) async {
    _repository = ref.watch(matchRepositoryProvider);
    _args = args;

    ref.onDispose(() {
      _matchesSubscription?.cancel();
    });

    final isCoach = await _repository!.isCoach(args.userId);

    _matchesSubscription = _repository!
        .watchTeamMatches(args.teamId)
        .listen(_handleMatchesUpdate, onError: _handleError);

    return MatchesState.initial(teamId: args.teamId, isCoach: isCoach);
  }

  Future<void> updateMatchNote({required String matchId, required String note}) async {
    final args = _args;
    if (args == null) return;
    try {
      await _repository?.updateMatchNote(
        teamId: args.teamId,
        matchId: matchId,
        note: note,
        userId: args.userId,
      );
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateMatchResult({
    required TeamMatch match,
    required bool played,
    int? goalsTeamA,
    int? goalsTeamB,
  }) async {
    final args = _args;
    if (args == null) return;
    try {
      await _repository?.updateMatchResult(
        teamId: args.teamId,
        match: match,
        played: played,
        goalsTeamA: goalsTeamA,
        goalsTeamB: goalsTeamB,
      );
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteMatch(TeamMatch match) async {
    final args = _args;
    if (args == null) return;
    try {
      await _repository?.deleteMatch(teamId: args.teamId, match: match);
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
      rethrow;
    }
  }

  void _handleMatchesUpdate(List<TeamMatch> matches) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(matches: matches));
  }

  void _handleError(Object error, StackTrace stackTrace) {
    state = AsyncError(error, stackTrace);
  }
}
