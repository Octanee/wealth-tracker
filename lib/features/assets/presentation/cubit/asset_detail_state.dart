import 'package:equatable/equatable.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_entry.dart';
import '../../../dashboard/domain/calculators/wealth_calculator.dart';

abstract class AssetDetailState extends Equatable {
  const AssetDetailState();
  @override
  List<Object?> get props => [];
}

class AssetDetailInitial extends AssetDetailState {
  const AssetDetailInitial();
}

class AssetDetailLoading extends AssetDetailState {
  const AssetDetailLoading();
}

class AssetDetailLoaded extends AssetDetailState {
  const AssetDetailLoaded({
    required this.asset,
    required this.entries,
    this.goldHistory = const <ChartPoint>[],
  });
  final Asset asset;
  final List<AssetEntry> entries;
  final List<ChartPoint> goldHistory;

  double? get latestValue => entries.isEmpty ? null : entries.first.value;

  double? get previousValue => entries.length < 2 ? null : entries[1].value;

  double? get changeAbsolute {
    if (latestValue == null || previousValue == null) return null;
    return latestValue! - previousValue!;
  }

  double? get changePercent {
    if (changeAbsolute == null || previousValue == 0) return null;
    return (changeAbsolute! / previousValue!) * 100;
  }

  @override
  List<Object?> get props => [asset, entries, goldHistory];
}

class AssetDetailError extends AssetDetailState {
  const AssetDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
