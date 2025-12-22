import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/core/providers/firebase_providers.dart';
import 'package:teampulse/features/matches/data/repositories/match_repository_impl.dart';
import 'package:teampulse/features/matches/domain/repositories/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return MatchRepositoryImpl(firestore: firestore, auth: auth);
});
