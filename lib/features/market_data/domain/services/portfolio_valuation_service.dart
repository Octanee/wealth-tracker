import '../../../assets/domain/entities/asset.dart';
import '../../../assets/domain/entities/asset_config.dart';
import '../../../assets/domain/entities/asset_entry.dart';
import '../../../dashboard/domain/calculators/wealth_calculator.dart';
import '../entities/asset_valuation.dart';
import 'asset_valuation_service.dart';

class PortfolioValuationResult {
  const PortfolioValuationResult({
    required this.valuationsByAssetId,
    required this.totalValue,
    required this.allocationPercents,
    required this.history,
  });

  final Map<String, AssetValuation> valuationsByAssetId;
  final double totalValue;
  final Map<String, double> allocationPercents;
  final List<ChartPoint> history;
}

class PortfolioValuationService {
  PortfolioValuationService({
    required AssetValuationService assetValuationService,
  }) : _assetValuationService = assetValuationService;

  final AssetValuationService _assetValuationService;

  Future<PortfolioValuationResult> build({
    required List<Asset> assets,
    required String baseCurrency,
    required Map<String, List<AssetEntry>> entriesByAsset,
  }) async {
    final valuations = <String, AssetValuation>{};
    for (final asset in assets) {
      final valuation = await _assetValuationService.valuateAsset(
        asset,
        baseCurrency: baseCurrency,
      );
      if (valuation != null && valuation.baseValue != null) {
        valuations[asset.id] = valuation;
      }
    }

    final totalValue = valuations.values.fold<double>(
      0,
      (sum, valuation) => sum + valuation.baseValue!,
    );

    final allocationPercents = <String, double>{};
    if (totalValue > 0) {
      for (final entry in valuations.entries) {
        allocationPercents[entry.key] =
            (entry.value.baseValue! / totalValue) * 100;
      }
    }

    final history = await _buildHistory(
      assets: assets,
      baseCurrency: baseCurrency,
      entriesByAsset: entriesByAsset,
    );

    return PortfolioValuationResult(
      valuationsByAssetId: valuations,
      totalValue: totalValue,
      allocationPercents: allocationPercents,
      history: history,
    );
  }

  Future<List<ChartPoint>> _buildHistory({
    required List<Asset> assets,
    required String baseCurrency,
    required Map<String, List<AssetEntry>> entriesByAsset,
  }) async {
    if (assets.isEmpty) return const [];

    final allDates = <DateTime>{};
    final today = _normalize(DateTime.now().toUtc());
    allDates.add(today);
    DateTime? minDate;

    for (final asset in assets) {
      final entries = entriesByAsset[asset.id] ?? const <AssetEntry>[];
      final startDate = _effectiveStartDate(asset, entries);
      allDates.add(startDate);
      if (minDate == null || startDate.isBefore(minDate)) {
        minDate = startDate;
      }
      for (final entry in entries) {
        final recordedAt = _normalize(entry.recordedAt);
        allDates.add(recordedAt);
        if (recordedAt.isBefore(minDate!)) {
          minDate = recordedAt;
        }
      }
    }

    if (minDate == null) return const [];
    // Promote to non-nullable for use in closures below.
    final effectiveMinDate = minDate;

    // ── Pre-fetch all data series in parallel ─────────────────────────────
    final hasGoldAssets = assets.any(
      (asset) => asset.config is MetalAssetConfig,
    );

    // Collect unique non-PLN currency codes needed for conversion.
    final currencyCodes = <String>{};
    for (final asset in assets) {
      final code = asset.currency.toUpperCase();
      if (code != 'PLN') currencyCodes.add(code);
    }
    final baseCode = baseCurrency.toUpperCase();
    if (baseCode != 'PLN') currencyCodes.add(baseCode);

    // Kick off all network calls in parallel.
    final fxSeriesByCode = <String, Map<DateTime, double>>{};
    Map<DateTime, double> goldSeries = const {};

    final futures = <Future>[
      for (final code in currencyCodes)
        _assetValuationService
            .getExchangeRateSeriesToPln(
              currencyCode: code,
              startDate: effectiveMinDate,
              endDate: today,
            )
            .then((s) => fxSeriesByCode[code] = s),
      if (hasGoldAssets)
        _assetValuationService
            .getGoldPriceSeriesPerGram(
              startDate: effectiveMinDate,
              endDate: today,
            )
            .then((s) {
              goldSeries = s;
              allDates.addAll(s.keys);
            }),
    ];
    await Future.wait(futures);

    // ── Build chart points with forward-fill ──────────────────────────────
    final sortedDates = allDates.toList()..sort();
    final points = <ChartPoint>[];

    // Forward-fill state: latest known PLN mid-rate per currency code.
    final latestRateToPln = <String, double>{'PLN': 1.0};
    double? latestGoldPricePln;

    for (final date in sortedDates) {
      if (goldSeries.containsKey(date)) {
        latestGoldPricePln = goldSeries[date];
      }
      for (final code in currencyCodes) {
        final rate = fxSeriesByCode[code]?[date];
        if (rate != null) latestRateToPln[code] = rate;
      }

      var total = 0.0;
      var hasAnyValue = false;

      for (final asset in assets) {
        final nativeValue = _resolveNativeValueOnDateSync(
          asset,
          entriesByAsset[asset.id] ?? const <AssetEntry>[],
          date,
          latestGoldPricePln: latestGoldPricePln,
          latestRateToPln: latestRateToPln,
        );
        if (nativeValue == null) continue;

        final rate = _exchangeRateSync(
          from: asset.currency.toUpperCase(),
          to: baseCode,
          latestRateToPln: latestRateToPln,
        );
        if (rate == null) continue;

        total += nativeValue * rate;
        hasAnyValue = true;
      }

      if (hasAnyValue) {
        points.add(ChartPoint(date: date, value: total));
      }
    }

    return points;
  }

  double? _resolveNativeValueOnDateSync(
    Asset asset,
    List<AssetEntry> entries,
    DateTime date, {
    required double? latestGoldPricePln,
    required Map<String, double> latestRateToPln,
  }) {
    final startDate = _effectiveStartDate(asset, entries);
    if (date.isBefore(startDate)) return null;

    if (asset.config case MetalAssetConfig(:final quantityGrams)) {
      if (latestGoldPricePln == null) return null;

      double effectiveQuantityGrams = quantityGrams;
      for (final entry in entries) {
        final entryDate = _normalize(entry.recordedAt);
        if (!entryDate.isAfter(date)) {
          effectiveQuantityGrams = entry.value;
        } else {
          break;
        }
      }

      final valueInPln = latestGoldPricePln * effectiveQuantityGrams;
      if (asset.currency.toUpperCase() == 'PLN') return valueInPln;

      // Convert PLN → asset.currency using latest known rate (1 assetCur = rate PLN).
      final assetCode = asset.currency.toUpperCase();
      final rate = latestRateToPln[assetCode];
      if (rate == null || rate == 0) return null;
      return valueInPln / rate;
    }

    double? lastValue;
    for (final entry in entries) {
      final entryDate = _normalize(entry.recordedAt);
      if (!entryDate.isAfter(date)) {
        lastValue = entry.value;
      } else {
        break;
      }
    }
    if (lastValue != null) return lastValue;

    if (asset.config case CashAssetConfig(:final cashAmount)) return cashAmount;

    return null;
  }

  /// Returns the exchange rate from [from] to [to] using forward-filled PLN rates.
  /// Returns null if a required rate has not yet been seen (forward-fill not reached).
  double? _exchangeRateSync({
    required String from,
    required String to,
    required Map<String, double> latestRateToPln,
  }) {
    if (from == to) return 1.0;
    final fromRate = from == 'PLN' ? 1.0 : latestRateToPln[from];
    final toRate = to == 'PLN' ? 1.0 : latestRateToPln[to];
    if (fromRate == null || toRate == null || toRate == 0) return null;
    return fromRate / toRate;
  }

  DateTime _effectiveStartDate(Asset asset, List<AssetEntry> entries) {
    if (entries.isEmpty) {
      return _normalize(asset.createdAt);
    }

    DateTime? earliest;
    for (final entry in entries) {
      final entryDate = _normalize(entry.recordedAt);
      if (earliest == null || entryDate.isBefore(earliest)) {
        earliest = entryDate;
      }
    }
    return earliest ?? _normalize(asset.createdAt);
  }

  DateTime _normalize(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}
