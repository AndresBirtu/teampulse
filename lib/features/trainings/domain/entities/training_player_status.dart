enum TrainingPresenceStatus { present, absent }

enum TrainingPunctualityStatus { onTime, late, unknown }

enum TrainingMetricLevel { low, medium, high }

enum TrainingRiskLevel { low, medium, high }

class TrainingPlayerStatus {
  const TrainingPlayerStatus({
    required this.playerId,
    required this.name,
    required this.presence,
    required this.punctuality,
    required this.fitness,
    required this.intensity,
    required this.technique,
    required this.assistance,
    required this.attitude,
    required this.injuryRisk,
    required this.note,
  });

  final String playerId;
  final String name;
  final TrainingPresenceStatus presence;
  final TrainingPunctualityStatus punctuality;
  final TrainingMetricLevel fitness;
  final TrainingMetricLevel intensity;
  final TrainingMetricLevel technique;
  final TrainingMetricLevel assistance;
  final TrainingMetricLevel attitude;
  final TrainingRiskLevel injuryRisk;
  final String note;

  bool get isPresent => presence == TrainingPresenceStatus.present;
  bool get isLate => punctuality == TrainingPunctualityStatus.late;

  TrainingPlayerStatus copyWith({
    String? playerId,
    String? name,
    TrainingPresenceStatus? presence,
    TrainingPunctualityStatus? punctuality,
    TrainingMetricLevel? fitness,
    TrainingMetricLevel? intensity,
    TrainingMetricLevel? technique,
    TrainingMetricLevel? assistance,
    TrainingMetricLevel? attitude,
    TrainingRiskLevel? injuryRisk,
    String? note,
  }) {
    return TrainingPlayerStatus(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      presence: presence ?? this.presence,
      punctuality: punctuality ?? this.punctuality,
      fitness: fitness ?? this.fitness,
      intensity: intensity ?? this.intensity,
      technique: technique ?? this.technique,
      assistance: assistance ?? this.assistance,
      attitude: attitude ?? this.attitude,
      injuryRisk: injuryRisk ?? this.injuryRisk,
      note: note ?? this.note,
    );
  }
}

TrainingPresenceStatus trainingPresenceFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'present':
      return TrainingPresenceStatus.present;
    case 'absent':
      return TrainingPresenceStatus.absent;
    default:
      return TrainingPresenceStatus.present;
  }
}

String trainingPresenceToString(TrainingPresenceStatus value) {
  return value == TrainingPresenceStatus.present ? 'present' : 'absent';
}

TrainingPunctualityStatus trainingPunctualityFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'on-time':
    case 'ontime':
    case 'on_time':
      return TrainingPunctualityStatus.onTime;
    case 'late':
      return TrainingPunctualityStatus.late;
    default:
      return TrainingPunctualityStatus.unknown;
  }
}

String trainingPunctualityToString(TrainingPunctualityStatus value) {
  switch (value) {
    case TrainingPunctualityStatus.onTime:
      return 'on-time';
    case TrainingPunctualityStatus.late:
      return 'late';
    case TrainingPunctualityStatus.unknown:
    default:
      return 'unknown';
  }
}

TrainingMetricLevel trainingMetricFromValue(int value) {
  if (value <= 1) return TrainingMetricLevel.low;
  if (value == 2) return TrainingMetricLevel.medium;
  return TrainingMetricLevel.high;
}

int trainingMetricToValue(TrainingMetricLevel level) {
  switch (level) {
    case TrainingMetricLevel.low:
      return 1;
    case TrainingMetricLevel.medium:
      return 2;
    case TrainingMetricLevel.high:
      return 3;
  }
}

TrainingRiskLevel trainingRiskFromValue(int value) {
  if (value <= 1) return TrainingRiskLevel.low;
  if (value == 2) return TrainingRiskLevel.medium;
  return TrainingRiskLevel.high;
}

int trainingRiskToValue(TrainingRiskLevel level) {
  switch (level) {
    case TrainingRiskLevel.low:
      return 1;
    case TrainingRiskLevel.medium:
      return 2;
    case TrainingRiskLevel.high:
      return 3;
  }
}
