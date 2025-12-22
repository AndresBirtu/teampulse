import 'package:teampulse/features/matches/domain/entities/match_player.dart';
import 'package:teampulse/features/matches/domain/entities/player_match_stat.dart';
import 'package:teampulse/features/matches/domain/entities/team_match.dart';

class MatchStatsState {
  const MatchStatsState({
    required this.teamId,
    required this.matchId,
    required this.matchDuration,
    required this.match,
    required this.stats,
    required this.players,
    required this.coachId,
    required this.isSaving,
    required this.isApplying,
  });

  final String teamId;
  final String matchId;
  final int matchDuration;
  final TeamMatch? match;
  final List<PlayerMatchStat> stats;
  final List<MatchPlayer> players;
  final String? coachId;
  final bool isSaving;
  final bool isApplying;

  factory MatchStatsState.initial({
    required String teamId,
    required String matchId,
    required int matchDuration,
    required String? coachId,
  }) {
    return MatchStatsState(
      teamId: teamId,
      matchId: matchId,
      matchDuration: matchDuration,
      match: null,
      stats: const [],
      players: const [],
      coachId: coachId,
      isSaving: false,
      isApplying: false,
    );
  }

  MatchStatsState copyWith({
    TeamMatch? match,
    bool updateMatch = false,
    List<PlayerMatchStat>? stats,
    List<MatchPlayer>? players,
    String? coachId,
    bool updateCoach = false,
    bool? isSaving,
    bool? isApplying,
  }) {
    return MatchStatsState(
      teamId: teamId,
      matchId: matchId,
      matchDuration: matchDuration,
      match: updateMatch ? match : (match ?? this.match),
      stats: stats ?? this.stats,
      players: players ?? this.players,
      coachId: updateCoach ? coachId : (coachId ?? this.coachId),
      isSaving: isSaving ?? this.isSaving,
      isApplying: isApplying ?? this.isApplying,
    );
  }

  PlayerMatchStat? statById(String playerId) {
    for (final stat in stats) {
      if (stat.playerId == playerId) return stat;
    }
    return null;
  }

  List<PlayerMatchStat> get visibleStats {
    final hiddenIds = <String>{};
    if (coachId != null && coachId!.isNotEmpty) hiddenIds.add(coachId!);
    for (final player in players) {
      if (player.isCoach) hiddenIds.add(player.id);
    }
    for (final stat in stats) {
      if (stat.isCoach) hiddenIds.add(stat.playerId);
    }
    return stats.where((stat) => !hiddenIds.contains(stat.playerId)).toList();
  }

  List<PlayerMatchStat> get titulares {
    return visibleStats.where((stat) => stat.titular).toList();
  }

  List<PlayerMatchStat> get suplentes {
    return visibleStats.where((stat) => !stat.titular).toList();
  }

  bool get hasStats => visibleStats.isNotEmpty;
  bool get matchPlayed => match?.played ?? false;
  bool get aggregated => match?.aggregated ?? false;
  bool get canApplyStats => matchPlayed && !aggregated;
  bool get canForceReapply => aggregated;
}
