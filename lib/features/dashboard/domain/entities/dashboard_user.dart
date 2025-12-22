class DashboardUser {
  const DashboardUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.teamId,
    this.teamName,
    this.teamCode,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String teamId;
  final String? teamName;
  final String? teamCode;

  bool get isCoach {
    final normalized = role.toLowerCase();
    return normalized == 'coach' || normalized == 'entrenador';
  }
}
