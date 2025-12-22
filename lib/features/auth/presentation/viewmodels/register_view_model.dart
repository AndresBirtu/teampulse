import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/auth/domain/entities/auth_role.dart';
import 'package:teampulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:teampulse/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:teampulse/features/auth/presentation/state/register_state.dart';

final registerViewModelProvider = AutoDisposeNotifierProvider<RegisterViewModel, RegisterState>(RegisterViewModel.new);

class RegisterViewModel extends AutoDisposeNotifier<RegisterState> {
  late final AuthRepository _repository;

  @override
  RegisterState build() {
    _repository = ref.watch(authRepositoryProvider);
    return RegisterState.initial();
  }

  void selectRole(AuthRole? role) {
    state = state.copyWith(selectedRole: role, setSelectedRole: true);
  }

  String generateTeamCode() => _repository.generateTeamCode();

  Future<bool> registerCoach({
    required String name,
    required String email,
    required String password,
    required String teamName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.registerCoach(
        name: name,
        email: email,
        password: password,
        teamName: teamName,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> registerPlayer({
    required String name,
    required String email,
    required String password,
    required String teamCode,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.registerPlayer(
        name: name,
        email: email,
        password: password,
        teamCode: teamCode,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }
}
