import 'package:teampulse/features/dashboard/domain/entities/dashboard_team.dart';
import 'package:teampulse/features/dashboard/domain/entities/dashboard_user.dart';

class DashboardState {
  const DashboardState({
    required this.userId,
    this.user,
    this.team,
    this.isCoach = false,
    this.isLoading = true,
    this.errorMessage,
  });

  final String userId;
  final DashboardUser? user;
  final DashboardTeam? team;
  final bool isCoach;
  final bool isLoading;
  final String? errorMessage;

  String get teamId => team?.id ?? user?.teamId ?? '';

  DashboardState copyWith({
    DashboardUser? user,
    DashboardTeam? team,
    bool? isCoach,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      userId: userId,
      user: user ?? this.user,
      team: team ?? this.team,
      isCoach: isCoach ?? this.isCoach,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  factory DashboardState.initial(String userId) => DashboardState(userId: userId);
}
