import 'package:teampulse/features/matches/domain/entities/match_availability.dart';
import 'package:teampulse/features/matches/domain/entities/match_player.dart';
import 'package:teampulse/features/matches/domain/entities/team_match.dart';

class MatchAvailabilityState {
  const MatchAvailabilityState({
    required this.teamId,
    required this.matchId,
    required this.isCoach,
    required this.match,
    required this.availabilities,
    required this.players,
  });

  final String teamId;
  final String matchId;
  final bool isCoach;
  final TeamMatch? match;
  final List<MatchAvailability> availabilities;
  final List<MatchPlayer> players;

  factory MatchAvailabilityState.initial({
    required String teamId,
    required String matchId,
    required bool isCoach,
  }) {
    return MatchAvailabilityState(
      teamId: teamId,
      matchId: matchId,
      isCoach: isCoach,
      match: null,
      availabilities: const [],
      players: const [],
    );
  }

  MatchAvailabilityState copyWith({
    TeamMatch? match,
    bool updateMatch = false,
    List<MatchAvailability>? availabilities,
    List<MatchPlayer>? players,
  }) {
    return MatchAvailabilityState(
      teamId: teamId,
      matchId: matchId,
      isCoach: isCoach,
      match: updateMatch ? match : (match ?? this.match),
      availabilities: availabilities ?? this.availabilities,
      players: players ?? this.players,
    );
  }

  Map<String, MatchAvailability> get availabilityByPlayerId {
    final map = <String, MatchAvailability>{};
    for (final availability in availabilities) {
      map[availability.playerId] = availability;
    }
    return map;
  }

  Map<String, MatchPlayer> get playersById {
    final map = <String, MatchPlayer>{};
    for (final player in players) {
      map[player.id] = player;
    }
    return map;
  }

  MatchAvailability? availabilityFor(String playerId) {
    return availabilityByPlayerId[playerId];
  }

  bool isPlayerConvocado(String playerId) {
    final currentConvocados = match?.convocados ?? const <String>[];
    return currentConvocados.contains(playerId);
  }

  String? get coachMessage => match?.coachMessage;

  List<MatchPlayer> get squadPlayers {
    return players.where((player) => !player.isCoach).toList();
  }

  List<MatchAvailability> get filteredAvailabilities {
    final playerMap = playersById;
    return availabilities.where((availability) {
      final player = playerMap[availability.playerId];
      if (player == null) return true;
      return !player.isCoach;
    }).toList();
  }
}
