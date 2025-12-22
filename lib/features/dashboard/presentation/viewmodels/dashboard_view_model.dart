import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/dashboard/domain/entities/dashboard_team.dart';
import 'package:teampulse/features/dashboard/domain/entities/dashboard_user.dart';
import 'package:teampulse/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:teampulse/features/dashboard/presentation/providers/dashboard_repository_provider.dart';
import 'package:teampulse/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:teampulse/services/preferences_service.dart';
import 'package:teampulse/theme/app_themes.dart';

class DashboardViewArgs {
  const DashboardViewArgs({required this.userId});

  final String userId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardViewArgs && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

final dashboardViewModelProvider = AutoDisposeAsyncNotifierProviderFamily<DashboardViewModel, DashboardState, DashboardViewArgs>(
  DashboardViewModel.new,
);

class DashboardViewModel extends AutoDisposeFamilyAsyncNotifier<DashboardState, DashboardViewArgs> {
  DashboardRepository? _repository;
  DashboardViewArgs? _args;
  StreamSubscription<DashboardUser>? _userSubscription;
  StreamSubscription<DashboardTeam>? _teamSubscription;
  ThemeOption? _lastSyncedTheme;
  String? _activeTeamId;

  @override
  FutureOr<DashboardState> build(DashboardViewArgs args) {
    _repository = ref.watch(dashboardRepositoryProvider);
    _args = args;
    _lastSyncedTheme = PreferencesService.getSelectedTheme();
    state = AsyncData(DashboardState.initial(args.userId));

    ref.onDispose(() {
      _userSubscription?.cancel();
      _teamSubscription?.cancel();
    });

    _userSubscription = _repository!
        .watchUser(args.userId)
        .listen(_onUserUpdate, onError: _handleError);

    return state.value!;
  }

  void _onUserUpdate(DashboardUser user) {
    _updateState(
      (current) => current.copyWith(
        user: user,
        isCoach: user.isCoach,
        isLoading: false,
        clearError: true,
      ),
    );
    _subscribeToTeam(user.teamId);
  }

  void _subscribeToTeam(String? teamId) {
    if (teamId == null || teamId.isEmpty) {
      _teamSubscription?.cancel();
      _activeTeamId = null;
      return;
    }

    if (_activeTeamId == teamId) return;
    _teamSubscription?.cancel();
    _activeTeamId = teamId;

    _teamSubscription = _repository!
        .watchTeam(teamId)
        .listen(_onTeamUpdate, onError: _handleError);
  }

  void _onTeamUpdate(DashboardTeam team) {
    _updateState((current) => current.copyWith(team: team, clearError: true));
    final option = team.themeOption;
    if (option != null && option != _lastSyncedTheme) {
      _lastSyncedTheme = option;
      unawaited(PreferencesService.setSelectedTheme(option));
    }
  }

  Future<String> generateInviteLink() async {
    final repository = _repository;
    final teamId = _requireTeamId();
    if (repository == null) throw StateError('Repository not ready');
    return repository.buildInviteLink(teamId);
  }

  Future<void> invitePlayerByEmail(String email) async {
    final repository = _repository;
    final teamId = _requireTeamId();
    if (repository == null) throw StateError('Repository not ready');
    await repository.invitePlayerByEmail(teamId: teamId, email: email);
  }

  Future<void> markSanctionServed(String sanctionId) async {
    final repository = _repository;
    final teamId = _requireTeamId();
    if (repository == null) throw StateError('Repository not ready');
    await repository.markSanctionServed(teamId: teamId, sanctionId: sanctionId);
  }

  Future<void> signOut() async {
    final repository = _repository;
    if (repository == null) throw StateError('Repository not ready');
    await repository.signOut();
  }

  String _requireTeamId() {
    final current = state.value;
    final teamId = current?.teamId ?? '';
    if (teamId.isEmpty) {
      throw StateError('team_required');
    }
    return teamId;
  }

  void _handleError(Object error, StackTrace stackTrace) {
    state = AsyncError(error, stackTrace);
  }

  void _updateState(DashboardState Function(DashboardState current) transform) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(transform(current));
  }
}
