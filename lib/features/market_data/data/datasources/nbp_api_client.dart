import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class NbpApiClient {
  NbpApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://api.nbp.pl/api';
  final http.Client _client;

  Future<double> getMidRateToPln(String currencyCode, {DateTime? date}) async {
    final code = currencyCode.toUpperCase();
    if (code == 'PLN') return 1.0;

    if (date == null) {
      final json = await _getJson('/exchangerates/rates/a/$code/');
      return _parseMidRate(json);
    }

    try {
      final json = await _getJson(
        '/exchangerates/rates/a/$code/${_formatDate(date)}/',
      );
      return _parseMidRate(json);
    } on _NbpNotFoundException {
      return _getMidRateToPlnFallback(code, date);
    }
  }

  Future<double> getGoldPricePerGram({DateTime? date}) async {
    if (date == null) {
      final json = await _getJson('/cenyzlota/');
      return _parseGoldPrice(json);
    }

    try {
      final json = await _getJson('/cenyzlota/${_formatDate(date)}/');
      return _parseGoldPrice(json);
    } on _NbpNotFoundException {
      return _getGoldPricePerGramFallback(date);
    }
  }

  Future<Map<DateTime, double>> getGoldPriceSeriesPerGram({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = _normalizeDate(startDate);
    final end = _normalizeDate(endDate);
    if (start.isAfter(end)) return {};

    final series = <DateTime, double>{};
    var chunkStart = start;

    while (!chunkStart.isAfter(end)) {
      final chunkEndCandidate = chunkStart.add(const Duration(days: 92));
      final chunkEnd = chunkEndCandidate.isAfter(end) ? end : chunkEndCandidate;

      try {
        final json = await _getJson(
          '/cenyzlota/${_formatDate(chunkStart)}/${_formatDate(chunkEnd)}/',
        );
        final chunk = _parseGoldSeries(json);
        series.addAll(chunk);
      } on _NbpNotFoundException {
        // No publication in selected window (e.g. weekend-only range).
      }

      chunkStart = chunkEnd.add(const Duration(days: 1));
    }

    return series;
  }

  /// Fetches the full time series of PLN mid-rates for [currencyCode] in the
  /// given date range. Returns a map of normalized UTC dates to rate values.
  /// Requests are chunked into 90-day windows to stay within NBP API limits.
  Future<Map<DateTime, double>> getMidRateSeriesToPln(
    String currencyCode, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final code = currencyCode.toUpperCase();
    if (code == 'PLN') {
      // Build a map with 1.0 for every date in range — no HTTP needed.
      final start = _normalizeDate(startDate);
      final end = _normalizeDate(endDate);
      final result = <DateTime, double>{};
      var cursor = start;
      while (!cursor.isAfter(end)) {
        result[cursor] = 1.0;
        cursor = cursor.add(const Duration(days: 1));
      }
      return result;
    }

    final start = _normalizeDate(startDate);
    final end = _normalizeDate(endDate);
    if (start.isAfter(end)) return {};

    final series = <DateTime, double>{};
    var chunkStart = start;

    while (!chunkStart.isAfter(end)) {
      final chunkEndCandidate = chunkStart.add(const Duration(days: 90));
      final chunkEnd = chunkEndCandidate.isAfter(end) ? end : chunkEndCandidate;

      try {
        final json = await _getJson(
          '/exchangerates/rates/a/$code/${_formatDate(chunkStart)}/${_formatDate(chunkEnd)}/',
        );
        final chunk = _parseMidRateSeries(json);
        series.addAll(chunk);
      } on _NbpNotFoundException {
        // No publication in selected window (e.g. all-weekend range).
      }

      chunkStart = chunkEnd.add(const Duration(days: 1));
    }

    return series;
  }

  Future<double> _getMidRateToPlnFallback(String code, DateTime date) async {
    final startDate = date.subtract(const Duration(days: 7));
    final json = await _getJson(
      '/exchangerates/rates/a/$code/${_formatDate(startDate)}/${_formatDate(date)}/',
    );
    final rates = (json['rates'] as List<dynamic>? ?? const []);
    if (rates.isEmpty) {
      throw const FormatException('Brak kursu waluty w odpowiedzi NBP.');
    }
    return (rates.last['mid'] as num).toDouble();
  }

  Future<double> _getGoldPricePerGramFallback(DateTime date) async {
    final startDate = date.subtract(const Duration(days: 7));
    final json = await _getJson(
      '/cenyzlota/${_formatDate(startDate)}/${_formatDate(date)}/',
    );
    final items = json as List<dynamic>;
    if (items.isEmpty) {
      throw const FormatException('Brak ceny złota w odpowiedzi NBP.');
    }
    return (items.last['cena'] as num).toDouble();
  }

  Future<dynamic> _getJson(String path) async {
    final uri = Uri.parse('$_baseUrl$path?format=json');
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode == 404) {
      throw const _NbpNotFoundException();
    }
    if (response.statusCode != 200) {
      throw http.ClientException(
        'NBP API returned ${response.statusCode}',
        uri,
      );
    }

    return jsonDecode(response.body);
  }

  double _parseMidRate(dynamic json) {
    final rates = json['rates'] as List<dynamic>?;
    if (rates == null || rates.isEmpty) {
      throw const FormatException('Brak kursów w odpowiedzi NBP.');
    }
    return (rates.first['mid'] as num).toDouble();
  }

  double _parseGoldPrice(dynamic json) {
    final items = json as List<dynamic>;
    if (items.isEmpty) {
      throw const FormatException('Brak ceny złota w odpowiedzi NBP.');
    }
    return (items.first['cena'] as num).toDouble();
  }

  Map<DateTime, double> _parseGoldSeries(dynamic json) {
    final items = json as List<dynamic>;
    final series = <DateTime, double>{};

    for (final item in items) {
      final map = item as Map<String, dynamic>;
      final date = DateTime.parse(map['data'] as String).toUtc();
      final normalized = _normalizeDate(date);
      series[normalized] = (map['cena'] as num).toDouble();
    }

    return series;
  }

  Map<DateTime, double> _parseMidRateSeries(dynamic json) {
    final rates = (json['rates'] as List<dynamic>?) ?? const [];
    final series = <DateTime, double>{};
    for (final item in rates) {
      final map = item as Map<String, dynamic>;
      final date = DateTime.parse(map['effectiveDate'] as String).toUtc();
      final normalized = _normalizeDate(date);
      series[normalized] = (map['mid'] as num).toDouble();
    }
    return series;
  }

  String _formatDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date.toUtc());

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}

class _NbpNotFoundException implements Exception {
  const _NbpNotFoundException();
}
