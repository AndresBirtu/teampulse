enum TrainingMediaType { video, photo, document }

class TrainingMediaResource {
  const TrainingMediaResource({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String mediaUrl;
  final TrainingMediaType type;
  final DateTime? createdAt;

  bool get isPhoto => type == TrainingMediaType.photo;
  bool get isVideo => type == TrainingMediaType.video;

  TrainingMediaResource copyWith({
    String? id,
    String? title,
    String? description,
    String? mediaUrl,
    TrainingMediaType? type,
    DateTime? createdAt,
    bool updateCreatedAt = false,
  }) {
    return TrainingMediaResource(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      type: type ?? this.type,
      createdAt: updateCreatedAt ? createdAt : (createdAt ?? this.createdAt),
    );
  }
}

TrainingMediaType trainingMediaTypeFromString(String? type) {
  switch ((type ?? '').toLowerCase()) {
    case 'photo':
      return TrainingMediaType.photo;
    case 'document':
      return TrainingMediaType.document;
    case 'video':
    default:
      return TrainingMediaType.video;
  }
}

String trainingMediaTypeToString(TrainingMediaType type) {
  switch (type) {
    case TrainingMediaType.photo:
      return 'photo';
    case TrainingMediaType.document:
      return 'document';
    case TrainingMediaType.video:
      return 'video';
  }
}
