import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/features/assets/domain/entities/asset.dart';
import 'package:wealthlens/features/assets/domain/entities/asset_config.dart';
import 'package:wealthlens/features/assets/domain/entities/asset_entry.dart';
import 'package:wealthlens/features/assets/domain/entities/asset_type.dart';
import 'package:wealthlens/features/market_data/domain/repositories/exchange_rate_repository.dart';
import 'package:wealthlens/features/market_data/domain/services/asset_valuation_service.dart';
import 'package:wealthlens/features/market_data/domain/services/gold_history_service.dart';

void main() {
  group('GoldHistoryService', () {
    late GoldHistoryService service;

    setUp(() {
      service = GoldHistoryService(
        assetValuationService: AssetValuationService(
          ratesRepository: _FakeExchangeRateRepository(
            goldSeries: {
              _d(2026, 4, 10): 10,
              _d(2026, 4, 11): 11,
              _d(2026, 4, 13): 13,
            },
            exchangeRates: {
              ('PLN', 'USD'): 0.25,
              ('USD', 'PLN'): 4,
            },
          ),
        ),
      );
    });

    test('builds a daily series from asset creation date', () async {
      final asset = _goldAsset(
        id: 'gold-1',
        quantityGrams: 2,
        createdAt: _d(2026, 4, 10),
      );

      final history = await service.buildAssetHistory(
        asset: asset,
        entries: const [],
        endDate: _d(2026, 4, 13),
      );

      expect(history.map((point) => point.date), [
        _d(2026, 4, 10),
        _d(2026, 4, 11),
        _d(2026, 4, 12),
        _d(2026, 4, 13),
      ]);
      expect(
        history.map((point) => point.value),
        [20.0, 22.0, 22.0, 26.0],
      );
    });

    test('applies subsequent entry values from the entry date forward', () async {
      final asset = _goldAsset(
        id: 'gold-1',
        quantityGrams: 2,
        createdAt: _d(2026, 4, 10),
      );
      final entries = [
        _entry(
          id: 'entry-1',
          assetId: asset.id,
          value: 3,
          recordedAt: _d(2026, 4, 11),
        ),
      ];

      final history = await service.buildAssetHistory(
        asset: asset,
        entries: entries,
        endDate: _d(2026, 4, 13),
      );

      expect(
        history.map((point) => point.value),
        [20.0, 33.0, 33.0, 39.0],
      );
    });

    test('aggregates multiple gold assets into one combined history', () async {
      final first = _goldAsset(
        id: 'gold-1',
        quantityGrams: 2,
        createdAt: _d(2026, 4, 10),
      );
      final second = _goldAsset(
        id: 'gold-2',
        quantityGrams: 1,
        currency: 'USD',
        createdAt: _d(2026, 4, 11),
      );

      final history = await service.buildCombinedHistory(
        assets: [first, second],
        baseCurrency: 'PLN',
        entriesByAsset: {
          first.id: const [],
          second.id: [
            _entry(
              id: 'entry-2',
              assetId: second.id,
              value: 2,
              recordedAt: _d(2026, 4, 13),
            ),
          ],
        },
        endDate: _d(2026, 4, 13),
      );

      expect(history.map((point) => point.date), [
        _d(2026, 4, 10),
        _d(2026, 4, 11),
        _d(2026, 4, 12),
        _d(2026, 4, 13),
      ]);
      expect(
        history.map((point) => point.value),
        [20.0, 33.0, 33.0, 52.0],
      );
    });
  });
}

class _FakeExchangeRateRepository implements ExchangeRateRepository {
  _FakeExchangeRateRepository({
    required this.goldSeries,
    required this.exchangeRates,
  });

  final Map<DateTime, double> goldSeries;
  final Map<(String, String), double> exchangeRates;

  @override
  Future<double?> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  }) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    final rate = exchangeRates[(fromCurrency, toCurrency)];
    if (rate == null) return null;
    return amount * rate;
  }

  @override
  Future<double?> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  }) async {
    if (fromCurrency == toCurrency) return 1;
    return exchangeRates[(fromCurrency, toCurrency)];
  }

  @override
  Future<double?> getGoldPricePerGram({DateTime? date}) async {
    if (date == null) {
      final dates = goldSeries.keys.toList()..sort();
      if (dates.isEmpty) return null;
      return goldSeries[dates.last];
    }
    return goldSeries[_normalize(date)];
  }

  @override
  Future<Map<DateTime, double>> getGoldPriceSeriesPerGram({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStart = _normalize(startDate);
    final normalizedEnd = _normalize(endDate);

    return {
      for (final entry in goldSeries.entries)
        if (!entry.key.isBefore(normalizedStart) &&
            !entry.key.isAfter(normalizedEnd))
          entry.key: entry.value,
    };
  }

  DateTime _normalize(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}

Asset _goldAsset({
  required String id,
  required double quantityGrams,
  required DateTime createdAt,
  String currency = 'PLN',
}) {
  return Asset(
    id: id,
    name: id,
    type: AssetType.metal,
    currency: currency,
    color: '#D4AF37',
    isArchived: false,
    createdAt: createdAt,
    updatedAt: createdAt,
    config: MetalAssetConfig(
      metalType: PreciousMetalType.gold,
      quantityGrams: quantityGrams,
    ),
  );
}

AssetEntry _entry({
  required String id,
  required String assetId,
  required double value,
  required DateTime recordedAt,
}) {
  return AssetEntry(
    id: id,
    assetId: assetId,
    value: value,
    recordedAt: recordedAt,
    createdAt: recordedAt,
  );
}

DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);