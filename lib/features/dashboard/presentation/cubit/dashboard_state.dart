import 'package:equatable/equatable.dart';
import '../../../assets/domain/entities/asset.dart';

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
  });

  final List<Asset> assets;
  final Map<String, double> totalByCurrency;
  final Map<String, double> allocationPercents; // assetId → %

  List<Asset> get assetsWithValue =>
      assets.where((a) => a.latestSnapshot != null).toList();

  @override
  List<Object?> get props => [assets, totalByCurrency, allocationPercents];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
