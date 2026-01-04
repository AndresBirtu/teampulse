import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teampulse/features/dashboard/domain/entities/dashboard_team.dart';
import 'package:teampulse/features/dashboard/domain/entities/dashboard_user.dart';
import 'package:teampulse/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<DashboardUser> watchUser(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      return DashboardUser(
        id: snapshot.id,
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        role: (data['role'] as String?) ?? 'jugador',
        teamId: (data['teamId'] as String?) ?? '',
        teamName: data['teamName'] as String?,
        teamCode: data['teamCode'] as String?,
      );
    });
  }

  @override
  Stream<DashboardTeam> watchTeam(String teamId) {
    if (teamId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore.collection('teams').doc(teamId).snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      return DashboardTeam(
        id: snapshot.id,
        name: (data['name'] as String?) ?? '',
        teamCode: data['teamCode'] as String?,
        coachId: data['coachId'] as String?,
        theme: data['theme'] as String?,
      );
    });
  }

  @override
  Future<String> buildInviteLink(String teamId) async {
    final snapshot = await _firestore.collection('teams').doc(teamId).get();
    if (!snapshot.exists) {
      throw StateError('Team not found');
    }
    final data = snapshot.data() ?? <String, dynamic>{};
    final teamCode = (data['teamCode'] as String?) ?? '';
    if (teamCode.isEmpty) {
      throw StateError('Team does not have a teamCode');
    }
    return 'https://teampulse.app/join?teamCode=$teamCode';
  }

  @override
  Future<void> invitePlayerByEmail({required String teamId, required String email}) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw ArgumentError('Email is required');
    }

    final usersSnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: trimmedEmail)
        .limit(1)
        .get();

    if (usersSnapshot.docs.isEmpty) {
      throw StateError('user_not_found');
    }

    final userDoc = usersSnapshot.docs.first;
    final userId = userDoc.id;
    final userName = (userDoc.data()['name'] as String?) ?? 'Jugador';

    final teamRef = _firestore.collection('teams').doc(teamId);
    
    // Ejecutar ambas operaciones en paralelo
    await Future.wait([
      teamRef.collection('players').doc(userId).set({
        'name': userName,
        'email': trimmedEmail,
        'role': 'jugador',
        'goles': 0,
        'asistencias': 0,
        'posicion': '',
        'partidos': 0,
        'minutos': 0,
        'tarjetas_amarillas': 0,
        'tarjetas_rojas': 0,
        'teamId': teamId,
      }, SetOptions(merge: true)),
      _firestore.collection('users').doc(userId).set({
        'teamId': teamId,
      }, SetOptions(merge: true)),
    ]);
  }

  @override
  Future<void> markSanctionServed({required String teamId, required String sanctionId}) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('sanctions')
        .doc(sanctionId)
        .update({
      'status': 'served',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }
}
