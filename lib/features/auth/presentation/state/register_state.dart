import 'package:teampulse/features/auth/domain/entities/auth_role.dart';

class RegisterState {
  const RegisterState({
    this.selectedRole,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthRole? selectedRole;
  final bool isLoading;
  final String? errorMessage;

  factory RegisterState.initial() => const RegisterState();

  RegisterState copyWith({
    AuthRole? selectedRole,
    bool setSelectedRole = false,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RegisterState(
      selectedRole: setSelectedRole ? selectedRole : this.selectedRole,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
