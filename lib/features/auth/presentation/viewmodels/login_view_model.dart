import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:teampulse/features/auth/presentation/state/login_state.dart';

final loginViewModelProvider = AutoDisposeNotifierProvider<LoginViewModel, LoginState>(LoginViewModel.new);

class LoginViewModel extends AutoDisposeNotifier<LoginState> {
  @override
  LoginState build() => LoginState.initial();

  Future<bool> signIn({required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(errorMessage: 'Completa correo y contraseña');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signIn(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }
}
