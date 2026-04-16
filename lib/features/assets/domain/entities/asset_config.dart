import 'package:equatable/equatable.dart';

enum PreciousMetalType {
  gold;

  String get displayName {
    switch (this) {
      case PreciousMetalType.gold:
        return 'Złoto';
    }
  }
}

abstract class AssetConfig extends Equatable {
  const AssetConfig();
}

class CashAssetConfig extends AssetConfig {
  const CashAssetConfig({required this.cashAmount});

  final double cashAmount;

  @override
  List<Object> get props => [cashAmount];
}

class MetalAssetConfig extends AssetConfig {
  const MetalAssetConfig({
    required this.metalType,
    required this.quantityGrams,
  });

  final PreciousMetalType metalType;
  final double quantityGrams;

  @override
  List<Object> get props => [metalType, quantityGrams];
}
