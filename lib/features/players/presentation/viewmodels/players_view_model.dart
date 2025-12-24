import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/players/domain/entities/player.dart';
import 'package:teampulse/features/players/domain/entities/sanction.dart';
import 'package:teampulse/features/players/domain/repositories/player_repository.dart';
import 'package:teampulse/features/players/presentation/state/players_state.dart';
import 'package:teampulse/features/players/presentation/providers/player_repository_provider.dart';

class PlayersViewArgs {
  const PlayersViewArgs({required this.teamId, required this.userId});

  final String teamId;
  final String userId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayersViewArgs &&
        other.teamId == teamId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(teamId, userId);
}

final playersViewModelProvider = AutoDisposeAsyncNotifierProviderFamily<PlayersViewModel, PlayersState, PlayersViewArgs>(
  PlayersViewModel.new,
);

class PlayersViewModel extends AutoDisposeFamilyAsyncNotifier<PlayersState, PlayersViewArgs> {
  PlayersViewModel();

  PlayerRepository? _repository;
  PlayersViewArgs? _args;
  StreamSubscription<List<Player>>? _playersSubscription;
  StreamSubscription<List<Sanction>>? _sanctionsSubscription;

  @override
  FutureOr<PlayersState> build(PlayersViewArgs args) async {
    _repository = ref.watch(playerRepositoryProvider);
    _args = args;

    ref.onDispose(() {
      _playersSubscription?.cancel();
      _sanctionsSubscription?.cancel();
    });

    final isCoach = await _repository!.isCoach(args.userId);

    _playersSubscription = _repository!
        .watchTeamPlayers(args.teamId)
        .listen(_handlePlayersUpdate, onError: _handleError);

    _sanctionsSubscription = _repository!
        .watchPendingSanctions(args.teamId)
        .listen(_handleSanctionsUpdate, onError: _handleError);

    return PlayersState.initial(teamId: args.teamId, isCoach: isCoach);
  }

  void changeSort(PlayersSort sort) {
    _updateState((current) => current.copyWith(sort: sort));
  }

  void changeFilter(String position) {
    _updateState((current) => current.copyWith(filterPosition: position));
  }

  Future<void> markSanctionServed(String sanctionId) async {
    final args = _args;
    if (args == null) return;
    await _repository?.markSanctionServed(
      teamId: args.teamId,
      sanctionId: sanctionId,
      resolvedBy: args.userId,
    );
  }

  Future<void> markPlayerInjury(
    String playerId, {
    DateTime? estimatedReturn,
    String? injuryArea,
  }) async {
    final args = _args;
    if (args == null) return;
    await _repository?.markPlayerInjury(
      teamId: args.teamId,
      playerId: playerId,
      estimatedReturn: estimatedReturn,
      injuryArea: injuryArea,
    );
  }

  Future<void> clearPlayerInjury(String playerId) async {
    final args = _args;
    if (args == null) return;
    await _repository?.clearPlayerInjury(teamId: args.teamId, playerId: playerId);
  }

  Future<void> setCaptain(String playerId, bool isCaptain) async {
    final args = _args;
    if (args == null) return;
    await _repository?.setCaptain(
      teamId: args.teamId,
      playerId: playerId,
      isCaptain: isCaptain,
    );
  }

  void _handlePlayersUpdate(List<Player> players) {
    _updateState((current) => current.copyWith(players: players));
  }

  void _handleSanctionsUpdate(List<Sanction> sanctions) {
    _updateState((current) => current.copyWith(sanctions: sanctions));
  }

  void _handleError(Object error, StackTrace stackTrace) {
    state = AsyncError(error, stackTrace);
  }

  void _updateState(PlayersState Function(PlayersState current) transform) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(transform(current));
  }
}
