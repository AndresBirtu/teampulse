import 'package:teampulse/features/dashboard/domain/entities/dashboard_team.dart';
import 'package:teampulse/features/dashboard/domain/entities/dashboard_user.dart';

abstract class DashboardRepository {
  Stream<DashboardUser> watchUser(String userId);
  Stream<DashboardTeam> watchTeam(String teamId);
  Future<String> buildInviteLink(String teamId);
  Future<void> invitePlayerByEmail({required String teamId, required String email});
  Future<void> markSanctionServed({required String teamId, required String sanctionId});
  Future<void> signOut();
}
