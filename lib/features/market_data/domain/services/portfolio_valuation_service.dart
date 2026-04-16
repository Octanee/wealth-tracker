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
    final allDates = <DateTime>{};
    final today = _normalize(DateTime.now().toUtc());
    allDates.add(today);

    for (final asset in assets) {
      allDates.add(_normalize(asset.createdAt));
      for (final entry in entriesByAsset[asset.id] ?? const <AssetEntry>[]) {
        allDates.add(_normalize(entry.recordedAt));
      }
    }

    final sortedDates = allDates.toList()..sort();
    final points = <ChartPoint>[];

    for (final date in sortedDates) {
      var total = 0.0;
      var hasAnyValue = false;

      for (final asset in assets) {
        final nativeValue = await _resolveNativeValueOnDate(
          asset,
          entriesByAsset[asset.id] ?? const <AssetEntry>[],
          date,
        );
        if (nativeValue == null) continue;

        final converted = await _assetValuationService.valuateAsset(
          asset.copyWith(
            latestSnapshot: LatestSnapshot(
              value: nativeValue,
              recordedAt: date,
              entryId: asset.latestSnapshot?.entryId ?? 'derived',
            ),
          ),
          baseCurrency: baseCurrency,
          asOfDate: date,
        );

        if (converted?.baseValue == null) continue;
        total += converted!.baseValue!;
        hasAnyValue = true;
      }

      if (hasAnyValue) {
        points.add(ChartPoint(date: date, value: total));
      }
    }

    return points;
  }

  Future<double?> _resolveNativeValueOnDate(
    Asset asset,
    List<AssetEntry> entries,
    DateTime date,
  ) async {
    final normalizedCreatedAt = _normalize(asset.createdAt);
    if (date.isBefore(normalizedCreatedAt)) return null;

    if (asset.config is MetalAssetConfig) {
      return _assetValuationService.resolveNativeValue(asset, asOfDate: date);
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

    if (lastValue != null) {
      return lastValue;
    }

    if (asset.config case CashAssetConfig(:final cashAmount)) {
      return cashAmount;
    }

    return null;
  }

  DateTime _normalize(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}
