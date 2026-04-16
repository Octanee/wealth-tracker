import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository authRepository,
    required AnalyticsService analytics,
  }) : _authRepository = authRepository,
       _analytics = analytics,
       super(const AuthInitial()) {
    _init();
  }

  final AuthRepository _authRepository;
  final AnalyticsService _analytics;
  StreamSubscription? _authSub;

  void _init() {
    emit(const AuthLoading());
    _authSub = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        unawaited(_analytics.setUserId(user.uid));
        emit(AuthAuthenticated(user));
      } else {
        unawaited(_analytics.setUserId(null));
        emit(const AuthUnauthenticated());
      }
    }, onError: (e) => emit(AuthError(e.toString())));
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      unawaited(_analytics.logLogin(method: 'google'));
      unawaited(_analytics.setUserId(user.uid));
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_friendlyError(e)));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      unawaited(_analytics.logLogin(method: 'email'));
      unawaited(_analytics.setUserId(user.uid));
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_friendlyError(e)));
    }
  }

  Future<void> register(String email, String password, String name) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name,
      );
      unawaited(_analytics.logSignUp(method: 'email'));
      unawaited(_analytics.setUserId(user.uid));
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_friendlyError(e)));
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      unawaited(_analytics.setUserId(null));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(_friendlyError(e)));
    }
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) return 'Nie znaleziono użytkownika';
    if (msg.contains('wrong-password')) return 'Nieprawidłowe hasło';
    if (msg.contains('email-already-in-use')) return 'E-mail jest już zajęty';
    if (msg.contains('invalid-email')) return 'Nieprawidłowy adres e-mail';
    if (msg.contains('weak-password')) {
      return 'Hasło jest za słabe (min. 6 znaków)';
    }
    if (msg.contains('network-request-failed')) {
      return 'Brak połączenia z internetem';
    }
    if (msg.contains('cancelled')) return 'Logowanie anulowane';
    return 'Wystąpił błąd. Spróbuj ponownie.';
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
