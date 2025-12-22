class TeamMatch {
  const TeamMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.date,
    required this.played,
    required this.goalsTeamA,
    required this.goalsTeamB,
    required this.aggregated,
    required this.note,
    required this.convocados,
    this.coachMessage,
    this.coachMessageUpdatedAt,
  });

  final String id;
  final String teamA;
  final String teamB;
  final DateTime? date;
  final bool played;
  final int goalsTeamA;
  final int goalsTeamB;
  final bool aggregated;
  final String note;
  final List<String> convocados;
  final String? coachMessage;
  final DateTime? coachMessageUpdatedAt;

  bool get hasResult => played;
  bool get hasNote => note.trim().isNotEmpty;

  TeamMatch copyWith({
    String? id,
    String? teamA,
    String? teamB,
    DateTime? date,
    bool? played,
    int? goalsTeamA,
    int? goalsTeamB,
    bool? aggregated,
    String? note,
    List<String>? convocados,
    String? coachMessage,
    DateTime? coachMessageUpdatedAt,
  }) {
    return TeamMatch(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      date: date ?? this.date,
      played: played ?? this.played,
      goalsTeamA: goalsTeamA ?? this.goalsTeamA,
      goalsTeamB: goalsTeamB ?? this.goalsTeamB,
      aggregated: aggregated ?? this.aggregated,
      note: note ?? this.note,
      convocados: convocados ?? this.convocados,
      coachMessage: coachMessage ?? this.coachMessage,
      coachMessageUpdatedAt: coachMessageUpdatedAt ?? this.coachMessageUpdatedAt,
    );
  }
}
