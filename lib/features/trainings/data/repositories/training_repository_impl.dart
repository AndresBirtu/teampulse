import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teampulse/features/trainings/domain/entities/training_media_resource.dart';
import 'package:teampulse/features/trainings/domain/entities/training_player.dart';
import 'package:teampulse/features/trainings/domain/entities/training_player_status.dart';
import 'package:teampulse/features/trainings/domain/entities/training_session.dart';
import 'package:teampulse/features/trainings/domain/repositories/training_repository.dart';

class TrainingRepositoryImpl implements TrainingRepository {
  TrainingRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<TrainingSession>> watchTrainings(String teamId) {
    return _trainingsCollection(teamId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapTrainingSession(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<TrainingMediaResource>> watchTrainingMedia(String teamId) {
    return _trainingMediaCollection(teamId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapTrainingMedia(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<TrainingSession?> loadTraining(String teamId, String trainingId) async {
    final doc = await _trainingDoc(teamId, trainingId).get();
    final data = doc.data();
    if (data == null) return null;
    return _mapTrainingSession(doc.id, data);
  }

  @override
  Future<List<TrainingPlayer>> loadTeamPlayers(String teamId) async {
    final snapshot = await _playersCollection(teamId).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return TrainingPlayer(
        id: doc.id,
        name: (data['name'] as String?)?.trim().isNotEmpty == true
            ? (data['name'] as String).trim()
            : 'Jugador',
      );
    }).toList();
  }

  @override
  Future<bool> isCoach(String userId) async {
    final resolvedUserId = userId.isNotEmpty ? userId : _auth.currentUser?.uid;
    if (resolvedUserId == null) return false;
    final doc = await _firestore.collection('users').doc(resolvedUserId).get();
    final role = (doc.data()?['role'] as String?)?.toLowerCase() ?? '';
    return role == 'coach' || role == 'entrenador';
  }

  @override
  Future<String> saveTraining({
    required String teamId,
    String? trainingId,
    required DateTime date,
    required String notes,
    required Map<String, TrainingPlayerStatus> players,
    required bool completed,
  }) async {
    final payload = <String, dynamic>{
      'date': Timestamp.fromDate(date),
      'notes': notes.trim(),
      'players': players.map((key, value) => MapEntry(key, _playerStatusToJson(value))),
      'completed': completed,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (trainingId == null) {
      final ref = await _trainingsCollection(teamId).add({
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } else {
      await _trainingDoc(teamId, trainingId).set(payload, SetOptions(merge: true));
      return trainingId;
    }
  }

  @override
  Future<void> deleteTraining({
    required String teamId,
    required String trainingId,
  }) {
    return _trainingDoc(teamId, trainingId).delete();
  }

  @override
  Future<void> addTrainingMedia({
    required String teamId,
    required String title,
    required TrainingMediaType type,
    required String mediaUrl,
    String? description,
  }) {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'description': (description ?? '').trim(),
      'mediaUrl': mediaUrl.trim(),
      'type': trainingMediaTypeToString(type),
      'createdBy': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };
    return _trainingMediaCollection(teamId).add(payload);
  }

  @override
  Future<void> deleteTrainingMedia({
    required String teamId,
    required String mediaId,
  }) {
    return _trainingMediaCollection(teamId).doc(mediaId).delete();
  }

  CollectionReference<Map<String, dynamic>> _trainingsCollection(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('trainings');
  }

  DocumentReference<Map<String, dynamic>> _trainingDoc(String teamId, String trainingId) {
    return _trainingsCollection(teamId).doc(trainingId);
  }

  CollectionReference<Map<String, dynamic>> _trainingMediaCollection(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('trainingMedia');
  }

  CollectionReference<Map<String, dynamic>> _playersCollection(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('players');
  }

  TrainingSession _mapTrainingSession(String id, Map<String, dynamic> data) {
    return TrainingSession(
      id: id,
      date: _timestampToDate(data['date']),
      notes: (data['notes'] as String?)?.trim() ?? '',
      players: _mapPlayers(data['players']),
      completed: data['completed'] == true,
      createdAt: _timestampToDate(data['createdAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
    );
  }

  TrainingMediaResource _mapTrainingMedia(String id, Map<String, dynamic> data) {
    return TrainingMediaResource(
      id: id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : 'Recurso',
      description: (data['description'] as String?)?.trim() ?? '',
      mediaUrl: (data['mediaUrl'] as String?)?.trim() ?? '',
      type: trainingMediaTypeFromString(data['type'] as String?),
      createdAt: _timestampToDate(data['createdAt']),
    );
  }

  Map<String, TrainingPlayerStatus> _mapPlayers(dynamic rawPlayers) {
    if (rawPlayers is! Map<String, dynamic>) return const {};
    final mapped = <String, TrainingPlayerStatus>{};
    rawPlayers.forEach((playerId, value) {
      if (value is! Map<String, dynamic>) return;
      mapped[playerId] = _mapPlayerStatus(playerId, value);
    });
    return mapped;
  }

  TrainingPlayerStatus _mapPlayerStatus(String playerId, Map<String, dynamic> data) {
    return TrainingPlayerStatus(
      playerId: playerId,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Jugador',
      presence: trainingPresenceFromString(data['presence'] as String?),
      punctuality: trainingPunctualityFromString(data['punctuality'] as String?),
      fitness: trainingMetricFromValue(_asInt(data['fitness'])),
      intensity: trainingMetricFromValue(_asInt(data['intensity'])),
      technique: trainingMetricFromValue(_asInt(data['technique'])),
      assistance: trainingMetricFromValue(_asInt(data['assistance'])),
      attitude: trainingMetricFromValue(_asInt(data['attitude'])),
      injuryRisk: trainingRiskFromValue(_asInt(data['injuryRisk'])),
      note: (data['note'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> _playerStatusToJson(TrainingPlayerStatus status) {
    return {
      'playerId': status.playerId,
      'name': status.name,
      'presence': trainingPresenceToString(status.presence),
      'punctuality': trainingPunctualityToString(status.punctuality),
      'fitness': trainingMetricToValue(status.fitness),
      'intensity': trainingMetricToValue(status.intensity),
      'technique': trainingMetricToValue(status.technique),
      'assistance': trainingMetricToValue(status.assistance),
      'attitude': trainingMetricToValue(status.attitude),
      'injuryRisk': trainingRiskToValue(status.injuryRisk),
      'note': status.note,
    };
  }

  DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return 0;
  }
}
