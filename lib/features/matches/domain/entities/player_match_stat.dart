class PlayerMatchStat {
  const PlayerMatchStat({
    required this.playerId,
    required this.playerName,
    required this.convocado,
    required this.titular,
    required this.isCoach,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    required this.minutes,
  });

  final String playerId;
  final String playerName;
  final bool convocado;
  final bool titular;
  final bool isCoach;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int minutes;

  bool get isStarter => titular;

  PlayerMatchStat copyWith({
    String? playerId,
    String? playerName,
    bool? convocado,
    bool? titular,
    bool? isCoach,
    int? goals,
    int? assists,
    int? yellowCards,
    int? redCards,
    int? minutes,
  }) {
    return PlayerMatchStat(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      convocado: convocado ?? this.convocado,
      titular: titular ?? this.titular,
      isCoach: isCoach ?? this.isCoach,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      minutes: minutes ?? this.minutes,
    );
  }
}
