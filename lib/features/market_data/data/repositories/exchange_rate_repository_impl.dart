import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/exchange_rate_repository.dart';
import '../datasources/nbp_api_client.dart';

class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  ExchangeRateRepositoryImpl({
    required NbpApiClient apiClient,
    required SharedPreferences preferences,
  }) : _apiClient = apiClient,
       _preferences = preferences;

  final NbpApiClient _apiClient;
  final SharedPreferences _preferences;

  @override
  Future<double?> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  }) async {
    final rate = await getExchangeRate(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      date: date,
    );
    if (rate == null) return null;
    return amount * rate;
  }

  @override
  Future<double?> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  }) async {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();
    if (from == to) return 1.0;
    if (!_isSupportedCurrency(from) || !_isSupportedCurrency(to)) {
      return null;
    }

    final cacheKey = _cacheKey('fx', '$from-$to', date);
    final cached = _preferences.getDouble(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final rate = await _fetchExchangeRate(
        fromCurrency: from,
        toCurrency: to,
        date: date,
      );
      _preferences.setDouble(cacheKey, rate);
      return rate;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<double?> getGoldPricePerGram({DateTime? date}) async {
    final cacheKey = _cacheKey('gold', 'pln-per-gram', date);
    final cached = _preferences.getDouble(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final price = await _apiClient.getGoldPricePerGram(date: date);
      _preferences.setDouble(cacheKey, price);
      return price;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<Map<DateTime, double>> getGoldPriceSeriesPerGram({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = _normalizeDate(startDate);
    final end = _normalizeDate(endDate);
    if (start.isAfter(end)) return {};

    try {
      final series = await _apiClient.getGoldPriceSeriesPerGram(
        startDate: start,
        endDate: end,
      );
      for (final entry in series.entries) {
        _preferences.setDouble(
          _cacheKey('gold', 'pln-per-gram', entry.key),
          entry.value,
        );
      }
      if (series.isNotEmpty) {
        return series;
      }
    } catch (_) {
      // Fall through to cached lookup.
    }

    return _readCachedGoldSeries(start: start, end: end);
  }

  Future<double> _fetchExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  }) async {
    if (fromCurrency == 'PLN') {
      final toRate = await _apiClient.getMidRateToPln(toCurrency, date: date);
      return 1 / toRate;
    }

    if (toCurrency == 'PLN') {
      return _apiClient.getMidRateToPln(fromCurrency, date: date);
    }

    final fromRate = await _apiClient.getMidRateToPln(fromCurrency, date: date);
    final toRate = await _apiClient.getMidRateToPln(toCurrency, date: date);
    return fromRate / toRate;
  }

  bool _isSupportedCurrency(String code) =>
      AppConstants.nbpSupportedCurrencies.contains(code);

  String _cacheKey(String prefix, String key, DateTime? date) {
    final normalizedDate = date == null
        ? DateTime.now().toUtc()
        : DateTime.utc(date.year, date.month, date.day);
    final datePart =
        '${normalizedDate.year.toString().padLeft(4, '0')}-'
        '${normalizedDate.month.toString().padLeft(2, '0')}-'
        '${normalizedDate.day.toString().padLeft(2, '0')}';
    return 'nbp.$prefix.$key.$datePart';
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  Map<DateTime, double> _readCachedGoldSeries({
    required DateTime start,
    required DateTime end,
  }) {
    final result = <DateTime, double>{};
    var cursor = start;
    while (!cursor.isAfter(end)) {
      final cached = _preferences.getDouble(
        _cacheKey('gold', 'pln-per-gram', cursor),
      );
      if (cached != null) {
        result[cursor] = cached;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }
}
