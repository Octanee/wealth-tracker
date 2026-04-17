import '../../../assets/domain/entities/asset.dart';
import '../../../assets/domain/entities/asset_config.dart';
import '../../../assets/domain/entities/asset_entry.dart';
import '../../../dashboard/domain/calculators/wealth_calculator.dart';
import 'asset_valuation_service.dart';

class GoldHistoryService {
  GoldHistoryService({required AssetValuationService assetValuationService})
    : _assetValuationService = assetValuationService;

  final AssetValuationService _assetValuationService;

  Future<List<ChartPoint>> buildCombinedHistory({
    required List<Asset> assets,
    required String baseCurrency,
    required Map<String, List<AssetEntry>> entriesByAsset,
    DateTime? endDate,
  }) {
    final goldAssets = assets.where((asset) => asset.isGoldAsset).toList();
    return _buildHistory(
      assets: goldAssets,
      outputCurrency: baseCurrency,
      entriesByAsset: entriesByAsset,
      endDate: endDate,
    );
  }

  Future<List<ChartPoint>> buildAssetHistory({
    required Asset asset,
    required List<AssetEntry> entries,
    String? outputCurrency,
    DateTime? endDate,
  }) {
    if (!asset.isGoldAsset) {
      return Future.value(const <ChartPoint>[]);
    }

    return _buildHistory(
      assets: [asset],
      outputCurrency: outputCurrency ?? asset.currency,
      entriesByAsset: {asset.id: entries},
      endDate: endDate,
    );
  }

  Future<List<ChartPoint>> _buildHistory({
    required List<Asset> assets,
    required String outputCurrency,
    required Map<String, List<AssetEntry>> entriesByAsset,
    DateTime? endDate,
  }) async {
    if (assets.isEmpty) return const <ChartPoint>[];

    final normalizedEndDate = _normalize(endDate ?? DateTime.now().toUtc());
    DateTime? minDate;
    final normalizedEntriesByAsset = <String, List<AssetEntry>>{};

    for (final asset in assets) {
      final entries =
          List<AssetEntry>.from(entriesByAsset[asset.id] ?? const <AssetEntry>[])
            ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      normalizedEntriesByAsset[asset.id] = entries;

      final startDate = _effectiveStartDate(asset, entries);
      if (minDate == null || startDate.isBefore(minDate)) {
        minDate = startDate;
      }
    }

    if (minDate == null || minDate.isAfter(normalizedEndDate)) {
      return const <ChartPoint>[];
    }
    // Promote to non-nullable for use in closures below.
    final effectiveMinDate = minDate;

    // ── Pre-fetch all data series in parallel ─────────────────────────────
    // Collect unique non-PLN currencies needed for conversion.
    final currencyCodes = <String>{};
    for (final asset in assets) {
      final code = asset.currency.toUpperCase();
      if (code != 'PLN') currencyCodes.add(code);
    }
    final outputCode = outputCurrency.toUpperCase();
    if (outputCode != 'PLN') currencyCodes.add(outputCode);

    final fxSeriesByCode = <String, Map<DateTime, double>>{};

    final futures = <Future>[
      for (final code in currencyCodes)
        _assetValuationService
            .getExchangeRateSeriesToPln(
              currencyCode: code,
              startDate: effectiveMinDate,
              endDate: normalizedEndDate,
            )
            .then((s) => fxSeriesByCode[code] = s),
    ];

    late final Map<DateTime, double> normalizedGoldSeries;
    futures.add(
      _assetValuationService
          .getGoldPriceSeriesPerGram(
            startDate: effectiveMinDate,
            endDate: normalizedEndDate,
          )
          .then(
            (raw) => normalizedGoldSeries = {
              for (final e in raw.entries) _normalize(e.key): e.value,
            },
          ),
    );

    await Future.wait(futures);

    // ── Build chart points with forward-fill ──────────────────────────────
    final points = <ChartPoint>[];
    // Forward-fill state.
    final latestRateToPln = <String, double>{'PLN': 1.0};
    double? latestGoldPricePln;

    for (DateTime date = effectiveMinDate;
        !date.isAfter(normalizedEndDate);
        date = date.add(const Duration(days: 1))) {
      if (normalizedGoldSeries.containsKey(date)) {
        latestGoldPricePln = normalizedGoldSeries[date];
      }
      for (final code in currencyCodes) {
        final rate = fxSeriesByCode[code]?[date];
        if (rate != null) latestRateToPln[code] = rate;
      }

      if (latestGoldPricePln == null) continue;

      var totalValue = 0.0;
      var hasAnyValue = false;

      for (final asset in assets) {
        final nativeValue = _resolveNativeValueOnDateSync(
          asset,
          normalizedEntriesByAsset[asset.id] ?? const <AssetEntry>[],
          date,
          latestGoldPricePln: latestGoldPricePln,
          latestRateToPln: latestRateToPln,
        );
        if (nativeValue == null) continue;

        // Convert asset.currency → outputCurrency synchronously.
        final rate = _exchangeRateSync(
          from: asset.currency.toUpperCase(),
          to: outputCode,
          latestRateToPln: latestRateToPln,
        );
        if (rate == null) continue;

        totalValue += nativeValue * rate;
        hasAnyValue = true;
      }

      if (hasAnyValue) {
        points.add(ChartPoint(date: date, value: totalValue));
      }
    }

    return points;
  }

  double? _resolveNativeValueOnDateSync(
    Asset asset,
    List<AssetEntry> entries,
    DateTime date, {
    required double latestGoldPricePln,
    required Map<String, double> latestRateToPln,
  }) {
    if (!asset.isGoldAsset) return null;

    final startDate = _effectiveStartDate(asset, entries);
    if (date.isBefore(startDate)) return null;

    final config = asset.metalConfig;
    if (config == null || config.metalType != PreciousMetalType.gold) {
      return null;
    }

    double effectiveQuantityGrams = config.quantityGrams;
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

    // Convert PLN → asset.currency using latest known rate.
    final assetCode = asset.currency.toUpperCase();
    final rate = latestRateToPln[assetCode];
    if (rate == null || rate == 0) return null;
    return valueInPln / rate;
  }

  /// Returns the exchange rate from [from] to [to] using forward-filled PLN rates.
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
    return _normalize(asset.createdAt);
  }

  DateTime _normalize(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}