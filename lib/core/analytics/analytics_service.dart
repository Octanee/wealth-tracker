import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService({required FirebaseAnalytics analytics})
    : _analytics = analytics;

  final FirebaseAnalytics _analytics;

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (_) {}
  }

  Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (_) {}
  }

  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (_) {}
  }

  Future<void> logDashboardViewed({required int assetsCount}) async {
    try {
      await _analytics.logEvent(
        name: 'dashboard_viewed',
        parameters: {'assets_count': assetsCount},
      );
    } catch (_) {}
  }

  Future<void> logAssetCreated({required String assetType}) async {
    try {
      await _analytics.logEvent(
        name: 'asset_created',
        parameters: {'asset_type': assetType},
      );
    } catch (_) {}
  }

  Future<void> logAssetArchived({required String assetType}) async {
    try {
      await _analytics.logEvent(
        name: 'asset_archived',
        parameters: {'asset_type': assetType},
      );
    } catch (_) {}
  }

  Future<void> logAssetDeleted({required String assetType}) async {
    try {
      await _analytics.logEvent(
        name: 'asset_deleted',
        parameters: {'asset_type': assetType},
      );
    } catch (_) {}
  }

  Future<void> logEntryAdded({required String assetId}) async {
    try {
      await _analytics.logEvent(
        name: 'entry_added',
        parameters: {'asset_id': assetId},
      );
    } catch (_) {}
  }

  Future<void> logEntryDeleted({required String assetId}) async {
    try {
      await _analytics.logEvent(
        name: 'entry_deleted',
        parameters: {'asset_id': assetId},
      );
    } catch (_) {}
  }

  Future<void> logSettingsCurrencyChanged({required String currency}) async {
    try {
      await _analytics.logEvent(
        name: 'settings_currency_changed',
        parameters: {'currency': currency},
      );
    } catch (_) {}
  }
}
