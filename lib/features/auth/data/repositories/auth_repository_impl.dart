import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teampulse/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _random = Random();

  @override
  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> registerCoach({
    required String name,
    required String email,
    required String password,
    required String teamName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    final teamCode = generateTeamCode();
    final teamsCollection = _firestore.collection('teams');

    final teamRef = await teamsCollection.add({
      'name': teamName,
      'coachId': uid,
      'ownerId': uid,
      'teamCode': teamCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Ejecutar ambas operaciones en paralelo
    await Future.wait([
      teamRef.collection('players').doc(uid).set({
        'playerId': uid,
        'teamId': teamRef.id,
        'name': name,
        'email': email,
        'role': 'entrenador',
        'goles': 0,
        'asistencias': 0,
        'posicion': '',
        'partidos': 0,
        'minutos': 0,
        'tarjetas_amarillas': 0,
        'tarjetas_rojas': 0,
      }),
      _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': 'entrenador',
        'teamId': teamRef.id,
        'teamName': teamName,
        'teamCode': teamCode,
      }, SetOptions(merge: true)),
    ]);
  }

  @override
  Future<void> registerPlayer({
    required String name,
    required String email,
    required String password,
    required String teamCode,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    final teams = await _firestore.collection('teams').where('teamCode', isEqualTo: teamCode).limit(1).get();

    if (teams.docs.isEmpty) {
      throw StateError('El código de equipo no existe');
    }

    final teamDoc = teams.docs.first;
    
    // Ejecutar ambas operaciones en paralelo
    await Future.wait([
      teamDoc.reference.collection('players').doc(uid).set({
        'playerId': uid,
        'teamId': teamDoc.id,
        'name': name,
        'email': email,
        'role': 'jugador',
        'goles': 0,
        'asistencias': 0,
        'posicion': '',
        'partidos': 0,
        'minutos': 0,
        'tarjetas_amarillas': 0,
        'tarjetas_rojas': 0,
      }),
      _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': 'jugador',
        'teamId': teamDoc.id,
        'teamName': teamDoc['name'],
        'teamCode': teamDoc['teamCode'],
      }, SetOptions(merge: true)),
    ]);
  }

  @override
  String generateTeamCode() {
    return List.generate(6, (_) => _chars[_random.nextInt(_chars.length)]).join();
  }
}
