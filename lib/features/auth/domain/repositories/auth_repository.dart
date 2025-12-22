abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});

  Future<void> registerCoach({
    required String name,
    required String email,
    required String password,
    required String teamName,
  });

  Future<void> registerPlayer({
    required String name,
    required String email,
    required String password,
    required String teamCode,
  });

  String generateTeamCode();
}
