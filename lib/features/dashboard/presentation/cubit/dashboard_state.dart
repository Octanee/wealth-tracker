import 'package:equatable/equatable.dart';
import '../../../assets/domain/entities/asset.dart';
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
    required this.totalByCurrency,
    required this.allocationPercents,
    this.portfolioHistory,
  });

  final List<Asset> assets;
  final Map<String, double> totalByCurrency;
  final Map<String, double> allocationPercents; // assetId → %
  /// null = history still loading; empty map = no entries yet
  final Map<String, List<ChartPoint>>? portfolioHistory;

  List<Asset> get assetsWithValue =>
      assets.where((a) => a.latestSnapshot != null).toList();

  DashboardLoaded withHistory(Map<String, List<ChartPoint>> history) =>
      DashboardLoaded(
        assets: assets,
        totalByCurrency: totalByCurrency,
        allocationPercents: allocationPercents,
        portfolioHistory: history,
      );

  @override
  List<Object?> get props => [
    assets,
    totalByCurrency,
    allocationPercents,
    portfolioHistory,
  ];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
