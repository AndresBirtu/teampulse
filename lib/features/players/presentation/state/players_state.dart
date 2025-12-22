import 'package:teampulse/features/players/domain/entities/player.dart';
import 'package:teampulse/features/players/domain/entities/sanction.dart';

enum PlayersSort { nameAsc, nameDesc, position }

class PlayersState {
  const PlayersState({
    required this.teamId,
    required this.isCoach,
    required this.players,
    required this.sanctions,
    required this.sort,
    required this.filterPosition,
  });

  final String teamId;
  final bool isCoach;
  final List<Player> players;
  final List<Sanction> sanctions;
  final PlayersSort sort;
  final String filterPosition;

  factory PlayersState.initial({required String teamId, required bool isCoach}) {
    return PlayersState(
      teamId: teamId,
      isCoach: isCoach,
      players: const [],
      sanctions: const [],
      sort: PlayersSort.nameAsc,
      filterPosition: '',
    );
  }

  PlayersState copyWith({
    String? teamId,
    bool? isCoach,
    List<Player>? players,
    List<Sanction>? sanctions,
    PlayersSort? sort,
    String? filterPosition,
  }) {
    return PlayersState(
      teamId: teamId ?? this.teamId,
      isCoach: isCoach ?? this.isCoach,
      players: players ?? this.players,
      sanctions: sanctions ?? this.sanctions,
      sort: sort ?? this.sort,
      filterPosition: filterPosition ?? this.filterPosition,
    );
  }

  Map<String, Sanction> get sanctionsByPlayerId {
    final map = <String, Sanction>{};
    for (final sanction in sanctions) {
      if (sanction.playerId.isNotEmpty) {
        map[sanction.playerId] = sanction;
      }
    }
    return map;
  }

  List<Player> get squadPlayers {
    return players.where((player) => !player.isCoach).toList();
  }

  List<Player> get filteredPlayers {
    var result = squadPlayers;
    if (filterPosition.isNotEmpty) {
      result = result
          .where((player) => player.position.toLowerCase() == filterPosition.toLowerCase())
          .toList();
    }
    result.sort((a, b) {
      switch (sort) {
        case PlayersSort.nameAsc:
          return a.name.compareTo(b.name);
        case PlayersSort.nameDesc:
          return b.name.compareTo(a.name);
        case PlayersSort.position:
          return a.position.compareTo(b.position);
      }
    });
    return result;
  }

  List<Player> get injuredPlayers {
    return filteredPlayers.where((player) => player.injured).toList();
  }

  List<Player> get sanctionedPlayers {
    final sanctionMap = sanctionsByPlayerId;
    return filteredPlayers.where((player) => sanctionMap.containsKey(player.id)).toList();
  }

  List<Player> get availablePlayers {
    final sanctionMap = sanctionsByPlayerId;
    return filteredPlayers
        .where((player) => !player.injured && !sanctionMap.containsKey(player.id))
        .toList();
  }
}
