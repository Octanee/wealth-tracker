import '../../domain/entities/asset_config.dart';
import '../../domain/entities/asset_type.dart';

class AssetConfigModel {
  const AssetConfigModel._();

  static Map<String, dynamic>? toFirestore(AssetConfig? config) {
    if (config == null) return null;

    return switch (config) {
      CashAssetConfig(:final cashAmount) => {
        'kind': 'cash',
        'cashAmount': cashAmount,
      },
      MetalAssetConfig(:final metalType, :final quantityGrams) => {
        'kind': 'metal',
        'metalType': metalType.name,
        'quantityGrams': quantityGrams,
      },
      _ => throw UnsupportedError('Unsupported asset config: $config'),
    };
  }

  static AssetConfig? fromFirestore(AssetType assetType, Object? rawConfig) {
    if (rawConfig is! Map) return null;
    final config = Map<String, dynamic>.from(rawConfig);

    switch (assetType) {
      case AssetType.bank:
      case AssetType.broker:
        final cashAmount = config['cashAmount'];
        if (cashAmount is num) {
          return CashAssetConfig(cashAmount: cashAmount.toDouble());
        }
        return null;
      case AssetType.metal:
        final quantityGrams = config['quantityGrams'];
        final metalName = config['metalType'] as String?;
        if (quantityGrams is! num) return null;
        final metalType = PreciousMetalType.values.firstWhere(
          (value) => value.name == metalName,
          orElse: () => PreciousMetalType.gold,
        );
        return MetalAssetConfig(
          metalType: metalType,
          quantityGrams: quantityGrams.toDouble(),
        );
      case AssetType.crypto:
      case AssetType.cash:
      case AssetType.other:
        return null;
    }
  }
}
