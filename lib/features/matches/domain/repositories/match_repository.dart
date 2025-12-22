import 'package:teampulse/features/matches/domain/entities/match_availability.dart';
import 'package:teampulse/features/matches/domain/entities/match_player.dart';
import 'package:teampulse/features/matches/domain/entities/player_match_stat.dart';
import 'package:teampulse/features/matches/domain/entities/team_match.dart';

class MatchCreationResult {
  const MatchCreationResult({
    required this.matchId,
    required this.statsGenerated,
  });

  final String matchId;
  final bool statsGenerated;
}

abstract class MatchRepository {
  Stream<List<TeamMatch>> watchTeamMatches(String teamId);
  Stream<TeamMatch?> watchMatch(String teamId, String matchId);
  Stream<List<MatchAvailability>> watchAvailability(String teamId, String matchId);
  Stream<List<MatchPlayer>> watchMatchPlayers(String teamId);
  Stream<List<PlayerMatchStat>> watchMatchStats(String teamId, String matchId);
  Future<bool> isCoach(String userId);
  Future<String?> loadTeamName(String teamId);
  Future<String?> loadTeamCoachId(String teamId);
  Future<MatchCreationResult> createMatch({
    required String teamId,
    required String teamA,
    required String teamB,
    required DateTime date,
    required bool played,
    int? goalsTeamA,
    int? goalsTeamB,
  });
  Future<void> updateMatchNote({
    required String teamId,
    required String matchId,
    required String note,
    required String userId,
  });
  Future<void> deleteMatch({
    required String teamId,
    required TeamMatch match,
  });
  Future<void> updateMatchResult({
    required String teamId,
    required TeamMatch match,
    required bool played,
    int? goalsTeamA,
    int? goalsTeamB,
  });
  Future<void> updateAvailability({
    required String teamId,
    required String matchId,
    required String playerId,
    required MatchAvailabilityStatus status,
    String? reason,
  });
  Future<void> toggleConvocado({
    required String teamId,
    required String matchId,
    required String playerId,
    required bool isConvocado,
  });
  Future<void> updateCoachMessage({
    required String teamId,
    required String matchId,
    required String? message,
  });
  Future<void> updatePlayerStats({
    required String teamId,
    required String matchId,
    required String playerId,
    required Map<String, dynamic> updates,
  });
  Future<void> ensureStatsAppliedIfNeeded({
    required String teamId,
    required String matchId,
  });
  Future<void> applyStatsToPlayers({
    required String teamId,
    required String matchId,
  });
  Future<void> revertStatsFromPlayers({
    required String teamId,
    required String matchId,
  });
  Future<void> registerRedCardSanction({
    required String teamId,
    required String matchId,
    required String playerId,
    required String playerName,
  });
  Future<void> removeRedCardSanction({
    required String teamId,
    required String matchId,
    required String playerId,
  });
}
