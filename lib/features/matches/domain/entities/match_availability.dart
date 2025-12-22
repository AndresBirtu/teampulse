enum MatchAvailabilityStatus { yes, maybe, no, unknown }

MatchAvailabilityStatus matchAvailabilityStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'yes':
      return MatchAvailabilityStatus.yes;
    case 'maybe':
      return MatchAvailabilityStatus.maybe;
    case 'no':
      return MatchAvailabilityStatus.no;
    default:
      return MatchAvailabilityStatus.unknown;
  }
}

String matchAvailabilityStatusToString(MatchAvailabilityStatus status) {
  switch (status) {
    case MatchAvailabilityStatus.yes:
      return 'yes';
    case MatchAvailabilityStatus.maybe:
      return 'maybe';
    case MatchAvailabilityStatus.no:
      return 'no';
    case MatchAvailabilityStatus.unknown:
      return 'unknown';
  }
}

class MatchAvailability {
  const MatchAvailability({
    required this.playerId,
    required this.playerName,
    required this.status,
    required this.reason,
    required this.updatedAt,
  });

  final String playerId;
  final String playerName;
  final MatchAvailabilityStatus status;
  final String reason;
  final DateTime? updatedAt;

  MatchAvailability copyWith({
    String? playerId,
    String? playerName,
    MatchAvailabilityStatus? status,
    String? reason,
    DateTime? updatedAt,
  }) {
    return MatchAvailability(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
