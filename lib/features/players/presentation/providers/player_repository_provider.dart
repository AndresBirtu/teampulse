import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/core/providers/firebase_providers.dart';
import 'package:teampulse/features/players/data/repositories/player_repository_impl.dart';
import 'package:teampulse/features/players/domain/repositories/player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return PlayerRepositoryImpl(firestore: firestore, auth: auth);
});
