class Player {
  const Player({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.position,
    required this.goals,
    required this.assists,
    required this.matches,
    required this.minutes,
    required this.yellowCards,
    required this.redCards,
    required this.injured,
    required this.injuryReturnDate,
    required this.injuryArea,
    required this.isCaptain,
    required this.photoUrl,
    required this.teamId,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String position;
  final int goals;
  final int assists;
  final int matches;
  final int minutes;
  final int yellowCards;
  final int redCards;
  final bool injured;
  final DateTime? injuryReturnDate;
  final String? injuryArea;
  final bool isCaptain;
  final String photoUrl;
  final String teamId;

  bool get isCoach {
    final normalizedRole = role.toLowerCase();
    return normalizedRole == 'entrenador' || normalizedRole == 'coach';
  }

  Map<String, dynamic> toEditableMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'posicion': position,
      'goles': goals,
      'asistencias': assists,
      'partidos': matches,
      'minutos': minutes,
      'tarjetas_amarillas': yellowCards,
      'tarjetas_rojas': redCards,
      'injured': injured,
      'injuryReturnDate': injuryReturnDate,
      'injuryArea': injuryArea,
      'isCaptain': isCaptain,
      'photoUrl': photoUrl,
      'teamId': teamId,
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? position,
    int? goals,
    int? assists,
    int? matches,
    int? minutes,
    int? yellowCards,
    int? redCards,
    bool? injured,
    DateTime? injuryReturnDate,
    String? injuryArea,
    bool? isCaptain,
    String? photoUrl,
    String? teamId,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      position: position ?? this.position,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      matches: matches ?? this.matches,
      minutes: minutes ?? this.minutes,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      injured: injured ?? this.injured,
      injuryReturnDate: injuryReturnDate ?? this.injuryReturnDate,
      injuryArea: injuryArea ?? this.injuryArea,
      isCaptain: isCaptain ?? this.isCaptain,
      photoUrl: photoUrl ?? this.photoUrl,
      teamId: teamId ?? this.teamId,
    );
  }
}
