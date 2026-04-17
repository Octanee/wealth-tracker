import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../assets/domain/entities/asset.dart';
import '../../../assets/domain/repositories/assets_repository.dart';
import '../../../market_data/domain/services/gold_history_service.dart';
import '../../../market_data/domain/services/portfolio_valuation_service.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required AssetsRepository repository,
    required PortfolioValuationService portfolioValuationService,
    required GoldHistoryService goldHistoryService,
    required AnalyticsService analytics,
  }) : _repository = repository,
       _portfolioValuationService = portfolioValuationService,
       _goldHistoryService = goldHistoryService,
       _analytics = analytics,
       super(const DashboardInitial());

  final AssetsRepository _repository;
  final PortfolioValuationService _portfolioValuationService;
  final GoldHistoryService _goldHistoryService;
  final AnalyticsService _analytics;
  StreamSubscription? _sub;
  String? _userId;
  String? _baseCurrency;
  List<Asset> _assets = const [];
  int _loadVersion = 0;

  void loadDashboard(String userId, String baseCurrency) {
    final sameUser = _userId == userId;
    _userId = userId;
    _baseCurrency = baseCurrency;

    if (!sameUser) {
      emit(const DashboardLoading());
      _sub?.cancel();
      _sub = _repository.watchAssets(userId).listen((assets) {
        _assets = assets;
        unawaited(_refreshDashboard());
      }, onError: (e) => emit(DashboardError(e.toString())));
      return;
    }

    unawaited(_refreshDashboard());
  }

  Future<void> reloadHistory(String userId) async {
    if (_userId != userId) return;
    await _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    if (_userId == null || _baseCurrency == null) return;

    final version = ++_loadVersion;
    try {
      final assets = List<Asset>.from(_assets);
      final entriesByAsset = await _repository.getAllEntries(
        _userId!,
        assets.map((asset) => asset.id).toList(),
      );
      final result = await _portfolioValuationService.build(
        assets: assets,
        baseCurrency: _baseCurrency!,
        entriesByAsset: entriesByAsset,
      );
      final goldHistory = await _goldHistoryService.buildCombinedHistory(
        assets: assets,
        baseCurrency: _baseCurrency!,
        entriesByAsset: entriesByAsset,
      );
      if (version != _loadVersion) return;

      emit(
        DashboardLoaded(
          assets: assets,
          baseCurrency: _baseCurrency!,
          totalValue: result.totalValue,
          valuationsByAssetId: result.valuationsByAssetId,
          allocationPercents: result.allocationPercents,
          portfolioHistory: result.history,
          goldHistory: goldHistory,
        ),
      );
      unawaited(_analytics.logDashboardViewed(assetsCount: assets.length));
    } catch (e) {
      if (version != _loadVersion) return;
      emit(DashboardError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
