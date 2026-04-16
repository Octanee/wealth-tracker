import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/constants/app_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _auth = firebaseAuth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference get _users => _firestore.collection('users');

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield null;
        return;
      }

      final existing = await _users.doc(user.uid).get();
      if (!existing.exists) {
        await _createUserDocument(user);
      }

      yield* _users.doc(user.uid).snapshots().map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          return UserEntity(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoUrl: user.photoURL,
            baseCurrency: AppConstants.defaultBaseCurrency,
          );
        }
        return UserEntity(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? data['displayName'] as String?,
          photoUrl: user.photoURL,
          baseCurrency:
              data['baseCurrency'] as String? ??
              AppConstants.defaultBaseCurrency,
        );
      });
    });
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final userCredential = await _auth.signInWithPopup(provider);
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: 'Nie udało się zalogować kontem Google.',
        );
      }
      return _fetchOrCreateUser(user);
    }

    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    if (credential.idToken == null) {
      throw FirebaseAuthException(
        code: 'google-token-missing',
        message: 'Brak tokenu Google do logowania.',
      );
    }

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Nie udało się zalogować kontem Google.',
      );
    }
    return _fetchOrCreateUser(user);
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchOrCreateUser(cred.user!);
  }

  @override
  Future<UserEntity> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    return _fetchOrCreateUser(cred.user!);
  }

  @override
  Future<void> signOut() async {
    if (kIsWeb) {
      await _auth.signOut();
      return;
    }

    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      await googleSignIn.signOut();
    } catch (_) {
      // Ignore provider-specific sign out issues; Firebase sign-out below
      // is the source of truth for app auth state.
    } finally {
      await _auth.signOut();
    }
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
      await _createUserDocument(firebaseUser);
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

  Future<void> _createUserDocument(User firebaseUser) {
    final data = {
      'displayName': firebaseUser.displayName ?? '',
      'email': firebaseUser.email ?? '',
      'baseCurrency': AppConstants.defaultBaseCurrency,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return _users.doc(firebaseUser.uid).set(data);
  }
}
