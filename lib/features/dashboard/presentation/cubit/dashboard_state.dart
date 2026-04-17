import 'package:equatable/equatable.dart';
import '../../../assets/domain/entities/asset.dart';
import '../../../market_data/domain/entities/asset_valuation.dart';
import '../../domain/calculators/wealth_calculator.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.assets,
    required this.baseCurrency,
    required this.totalValue,
    required this.valuationsByAssetId,
    required this.allocationPercents,
    this.portfolioHistory,
    this.goldHistory,
  });

  final List<Asset> assets;
  final String baseCurrency;
  final double totalValue;
  final Map<String, AssetValuation> valuationsByAssetId;
  final Map<String, double> allocationPercents; // assetId → %
  /// null = history still loading; empty = no points yet
  final List<ChartPoint>? portfolioHistory;
  final List<ChartPoint>? goldHistory;

  List<Asset> get assetsWithValue =>
      assets.where((a) => valuationsByAssetId.containsKey(a.id)).toList();

  bool get hasUnconvertedAssets => assetsWithValue.length != assets.length;

  bool get hasGoldAssets => assets.any((asset) => asset.isGoldAsset);

  DashboardLoaded withHistory(List<ChartPoint> history) => DashboardLoaded(
    assets: assets,
    baseCurrency: baseCurrency,
    totalValue: totalValue,
    valuationsByAssetId: valuationsByAssetId,
    allocationPercents: allocationPercents,
    portfolioHistory: history,
    goldHistory: goldHistory,
  );

  @override
  List<Object?> get props => [
    assets,
    baseCurrency,
    totalValue,
    valuationsByAssetId,
    allocationPercents,
    portfolioHistory,
    goldHistory,
  ];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
