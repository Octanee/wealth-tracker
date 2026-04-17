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
      final entries = List<AssetEntry>.from(entriesByAsset[asset.id] ?? const <AssetEntry>[])
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

    final rawGoldSeries = await _assetValuationService.getGoldPriceSeriesPerGram(
      startDate: minDate,
      endDate: normalizedEndDate,
    );

    final normalizedGoldSeries = <DateTime, double>{
      for (final entry in rawGoldSeries.entries) _normalize(entry.key): entry.value,
    };

    final points = <ChartPoint>[];
    double? latestGoldPricePln;

    for (DateTime date = minDate;
        !date.isAfter(normalizedEndDate);
        date = date.add(const Duration(days: 1))) {
      if (normalizedGoldSeries.containsKey(date)) {
        latestGoldPricePln = normalizedGoldSeries[date];
      }

      if (latestGoldPricePln == null) {
        continue;
      }

      var totalValue = 0.0;
      var hasAnyValue = false;

      for (final asset in assets) {
        final nativeValue = await _resolveNativeValueOnDate(
          asset,
          normalizedEntriesByAsset[asset.id] ?? const <AssetEntry>[],
          date,
          latestGoldPricePln: latestGoldPricePln,
        );
        if (nativeValue == null) continue;

        final converted = await _assetValuationService.convertAmount(
          amount: nativeValue,
          fromCurrency: asset.currency,
          toCurrency: outputCurrency,
          asOfDate: date,
        );
        if (converted == null) continue;

        totalValue += converted;
        hasAnyValue = true;
      }

      if (hasAnyValue) {
        points.add(ChartPoint(date: date, value: totalValue));
      }
    }

    return points;
  }

  Future<double?> _resolveNativeValueOnDate(
    Asset asset,
    List<AssetEntry> entries,
    DateTime date, {
    required double latestGoldPricePln,
  }) async {
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
    if (asset.currency == 'PLN') {
      return valueInPln;
    }

    return _assetValuationService.convertAmount(
      amount: valueInPln,
      fromCurrency: 'PLN',
      toCurrency: asset.currency,
      asOfDate: date,
    );
  }

  DateTime _effectiveStartDate(Asset asset, List<AssetEntry> entries) {
    return _normalize(asset.createdAt);
  }

  DateTime _normalize(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}