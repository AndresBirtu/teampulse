class MatchPlayer {
  const MatchPlayer({
    required this.id,
    required this.name,
    required this.isCoach,
  });

  final String id;
  final String name;
  final bool isCoach;

  MatchPlayer copyWith({
    String? id,
    String? name,
    bool? isCoach,
  }) {
    return MatchPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isCoach: isCoach ?? this.isCoach,
    );
  }
}
