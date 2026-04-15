import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/constants/app_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _auth = firebaseAuth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference get _users => _firestore.collection('users');

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _fetchOrCreateUser(user);
    });
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    // google_sign_in 7.x: use GoogleSignIn.instance + OAuthProvider
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();

    final googleUser = await googleSignIn.authenticate();
    // In 7.x, we use OAuthProvider to create Firebase credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return _fetchOrCreateUser(userCredential.user!);
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return _fetchOrCreateUser(cred.user!);
  }

  @override
  Future<UserEntity> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(displayName);
    return _fetchOrCreateUser(cred.user!);
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchOrCreateUser(user);
  }

  @override
  Future<void> updateBaseCurrency(String currency) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _users.doc(uid).update({
      'baseCurrency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserEntity> _fetchOrCreateUser(User firebaseUser) async {
    final doc = await _users.doc(firebaseUser.uid).get();
    if (!doc.exists) {
      final data = {
        'displayName': firebaseUser.displayName ?? '',
        'email': firebaseUser.email ?? '',
        'baseCurrency': AppConstants.defaultBaseCurrency,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _users.doc(firebaseUser.uid).set(data);
      return UserEntity(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        baseCurrency: AppConstants.defaultBaseCurrency,
      );
    }
    final data = doc.data() as Map<String, dynamic>;
    return UserEntity(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? data['displayName'] as String?,
      photoUrl: firebaseUser.photoURL,
      baseCurrency:
          data['baseCurrency'] as String? ?? AppConstants.defaultBaseCurrency,
    );
  }
}
