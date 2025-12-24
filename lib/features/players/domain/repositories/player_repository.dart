import 'package:teampulse/features/players/domain/entities/player.dart';
import 'package:teampulse/features/players/domain/entities/player_update.dart';
import 'package:teampulse/features/players/domain/entities/sanction.dart';

abstract class PlayerRepository {
  Stream<List<Player>> watchTeamPlayers(String teamId);
  Stream<List<Sanction>> watchPendingSanctions(String teamId);
  Future<bool> isCoach(String userId);
  Future<void> markSanctionServed({
    required String teamId,
    required String sanctionId,
    required String resolvedBy,
  });
  Future<void> markPlayerInjury({
    required String teamId,
    required String playerId,
    DateTime? estimatedReturn,
    String? injuryArea,
  });
  Future<void> clearPlayerInjury({
    required String teamId,
    required String playerId,
  });
  Future<void> setCaptain({
    required String teamId,
    required String playerId,
    required bool isCaptain,
  });
  Future<void> updatePlayerStats({
    required String teamId,
    required String playerId,
    required PlayerUpdate update,
  });
}
