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
  Set<String>? _lastAssetIds;

  void loadDashboard(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _lastAssetIds = null;
    emit(const DashboardLoading());
    _sub?.cancel();
    _sub = _repository.watchAssets(userId).listen((assets) {
      final totals = WealthCalculator.totalByCurrency(assets);
      final allocs = WealthCalculator.allocationPercents(assets);
      unawaited(_analytics.logDashboardViewed(assetsCount: assets.length));

      // Preserve existing history to avoid flickering null
      final currentHistory =
          state is DashboardLoaded
              ? (state as DashboardLoaded).portfolioHistory
              : null;

      emit(
        DashboardLoaded(
          assets: assets,
          totalByCurrency: totals,
          allocationPercents: allocs,
          portfolioHistory: currentHistory,
        ),
      );

      // Re-fetch history only when asset set changes
      final newIds = assets.map((a) => a.id).toSet();
      if (_lastAssetIds == null || !_setsEqual(_lastAssetIds!, newIds)) {
        _lastAssetIds = newIds;
        unawaited(
          _loadPortfolioHistory(userId, assets.map((a) => a.id).toList()),
        );
      }
    }, onError: (e) => emit(DashboardError(e.toString())));
  }

  Future<void> reloadHistory(String userId) async {
    if (state is! DashboardLoaded) return;
    final assetIds =
        (state as DashboardLoaded).assets.map((a) => a.id).toList();
    _lastAssetIds = null;
    await _loadPortfolioHistory(userId, assetIds);
  }

  Future<void> _loadPortfolioHistory(
    String userId,
    List<String> assetIds,
  ) async {
    if (state is! DashboardLoaded) return;
    try {
      final entriesByAsset =
          await _repository.getAllEntries(userId, assetIds);
      if (state is! DashboardLoaded) return;
      final loaded = state as DashboardLoaded;
      final history = WealthCalculator.portfolioHistory(
        loaded.assets,
        entriesByAsset,
      );
      if (state is DashboardLoaded) {
        emit((state as DashboardLoaded).withHistory(history));
      }
    } catch (_) {
      // History is non-critical; silently emit empty map so UI stops loading
      if (state is DashboardLoaded) {
        emit((state as DashboardLoaded).withHistory({}));
      }
    }
  }

  static bool _setsEqual(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
