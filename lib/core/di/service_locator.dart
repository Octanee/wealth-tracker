import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/assets/data/repositories/assets_repository_impl.dart';
import '../../features/assets/domain/repositories/assets_repository.dart';

/// Simple service locator — replace with get_it if scale demands it.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  late final AuthRepository authRepository;
  late final AssetsRepository assetsRepository;

  void setup() {
    final firebaseAuth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    authRepository = AuthRepositoryImpl(
      firebaseAuth: firebaseAuth,
      firestore: firestore,
    );

    assetsRepository = AssetsRepositoryImpl(firestore: firestore);
  }
}
