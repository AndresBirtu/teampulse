import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/core/providers/firebase_providers.dart';
import 'package:teampulse/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:teampulse/features/dashboard/domain/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return DashboardRepositoryImpl(firestore: firestore, auth: auth);
});
