const Map<String, String> kInjuryAreaLabels = {
  'head': 'Cabeza',
  'neck': 'Cuello',
  'shoulder': 'Hombro',
  'arm': 'Brazo',
  'hand': 'Mano',
  'chest': 'Pecho',
  'abdomen': 'Abdomen',
  'hip': 'Cadera',
  'thigh': 'Muslo',
  'knee': 'Rodilla',
  'leg': 'Pierna',
  'ankle': 'Tobillo',
  'foot': 'Pie',
};

String describeInjuryArea(String? areaId) {
  if (areaId == null || areaId.isEmpty) {
    return 'Zona general';
  }
  return kInjuryAreaLabels[areaId] ?? 'Zona general';
}
