import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required AuthRepository authRepository,
    required AnalyticsService analytics,
  }) : _authRepository = authRepository,
       _analytics = analytics,
       super(const SettingsInitial());

  final AuthRepository _authRepository;
  final AnalyticsService _analytics;

  void loadUser(UserEntity user) => emit(SettingsLoaded(user));

  Future<void> updateBaseCurrency(String currency) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    emit(SettingsSaving(current.user));
    await _authRepository.updateBaseCurrency(currency);
    await _analytics.logSettingsCurrencyChanged(currency: currency);
    emit(SettingsLoaded(current.user.copyWith(baseCurrency: currency)));
  }
}
