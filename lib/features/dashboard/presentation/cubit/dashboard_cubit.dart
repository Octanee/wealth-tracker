import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../assets/domain/repositories/assets_repository.dart';
import '../../../dashboard/domain/calculators/wealth_calculator.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required AssetsRepository repository,
    required AnalyticsService analytics,
  }) : _repository = repository,
       _analytics = analytics,
       super(const DashboardInitial());

  final AssetsRepository _repository;
  final AnalyticsService _analytics;
  StreamSubscription? _sub;
  String? _userId;

  void loadDashboard(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    emit(const DashboardLoading());
    _sub?.cancel();
    _sub = _repository.watchAssets(userId).listen((assets) {
      final totals = WealthCalculator.totalByCurrency(assets);
      final allocs = WealthCalculator.allocationPercents(assets);
      unawaited(_analytics.logDashboardViewed(assetsCount: assets.length));
      emit(
        DashboardLoaded(
          assets: assets,
          totalByCurrency: totals,
          allocationPercents: allocs,
        ),
      );
    }, onError: (e) => emit(DashboardError(e.toString())));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
