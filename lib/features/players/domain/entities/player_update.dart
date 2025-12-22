class PlayerUpdate {
  const PlayerUpdate({
    required this.position,
    required this.minutes,
    required this.goals,
    required this.assists,
    required this.matches,
    required this.yellowCards,
    required this.redCards,
  });

  final String position;
  final int minutes;
  final int goals;
  final int assists;
  final int matches;
  final int yellowCards;
  final int redCards;

  Map<String, dynamic> toJson() {
    return {
      'posicion': position,
      'minutos': minutes,
      'goles': goals,
      'asistencias': assists,
      'partidos': matches,
      'tarjetas_amarillas': yellowCards,
      'tarjetas_rojas': redCards,
    };
  }
}
