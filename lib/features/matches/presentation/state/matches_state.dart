import 'package:teampulse/features/matches/domain/entities/team_match.dart';

class MatchesState {
  const MatchesState({
    required this.teamId,
    required this.isCoach,
    required this.matches,
  });

  final String teamId;
  final bool isCoach;
  final List<TeamMatch> matches;

  factory MatchesState.initial({required String teamId, required bool isCoach}) {
    return MatchesState(
      teamId: teamId,
      isCoach: isCoach,
      matches: const [],
    );
  }

  MatchesState copyWith({
    String? teamId,
    bool? isCoach,
    List<TeamMatch>? matches,
  }) {
    return MatchesState(
      teamId: teamId ?? this.teamId,
      isCoach: isCoach ?? this.isCoach,
      matches: matches ?? this.matches,
    );
  }

  bool get hasMatches => matches.isNotEmpty;
}
