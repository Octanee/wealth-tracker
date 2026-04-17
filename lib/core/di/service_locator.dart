import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/assets/data/repositories/assets_repository_impl.dart';
import '../../features/assets/domain/repositories/assets_repository.dart';
import '../../features/market_data/data/datasources/nbp_api_client.dart';
import '../../features/market_data/data/repositories/exchange_rate_repository_impl.dart';
import '../../features/market_data/domain/repositories/exchange_rate_repository.dart';
import '../../features/market_data/domain/services/asset_valuation_service.dart';
import '../../features/market_data/domain/services/gold_history_service.dart';
import '../../features/market_data/domain/services/portfolio_valuation_service.dart';
import '../../features/goals/data/repositories/goals_repository_impl.dart';
import '../../features/goals/domain/repositories/goals_repository.dart';

/// Simple service locator — replace with get_it if scale demands it.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  late final AuthRepository authRepository;
  late final AssetsRepository assetsRepository;
  late final AnalyticsService analyticsService;
  late final ExchangeRateRepository exchangeRateRepository;
  late final AssetValuationService assetValuationService;
  late final GoldHistoryService goldHistoryService;
  late final PortfolioValuationService portfolioValuationService;
  late final GoalsRepository goalsRepository;

  Future<void> setup() async {
    final firebaseAuth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    final analytics = FirebaseAnalytics.instance;
    final preferences = await SharedPreferences.getInstance();
    final httpClient = http.Client();

    analyticsService = AnalyticsService(analytics: analytics);

    authRepository = AuthRepositoryImpl(
      firebaseAuth: firebaseAuth,
      firestore: firestore,
    );

    assetsRepository = AssetsRepositoryImpl(firestore: firestore);
    goalsRepository = GoalsRepositoryImpl(firestore: firestore);

    exchangeRateRepository = ExchangeRateRepositoryImpl(
      apiClient: NbpApiClient(client: httpClient),
      preferences: preferences,
    );

    assetValuationService = AssetValuationService(
      ratesRepository: exchangeRateRepository,
    );

    goldHistoryService = GoldHistoryService(
      assetValuationService: assetValuationService,
    );

    portfolioValuationService = PortfolioValuationService(
      assetValuationService: assetValuationService,
    );
  }
}
