import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/core/providers/firebase_providers.dart';
import 'package:teampulse/features/trainings/data/repositories/training_repository_impl.dart';
import 'package:teampulse/features/trainings/domain/repositories/training_repository.dart';

final trainingRepositoryProvider = Provider<TrainingRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return TrainingRepositoryImpl(firestore: firestore, auth: auth);
});
