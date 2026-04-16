enum AssetType {
  bank,
  broker,
  crypto,
  metal,
  cash,
  other;

  String get displayName {
    switch (this) {
      case AssetType.bank:
        return 'Konto bankowe';
      case AssetType.broker:
        return 'Konto maklerskie';
      case AssetType.crypto:
        return 'Kryptowaluty';
      case AssetType.metal:
        return 'Metale szlachetne';
      case AssetType.cash:
        return 'Gotówka';
      case AssetType.other:
        return 'Inne';
    }
  }

  String get icon {
    switch (this) {
      case AssetType.bank:
        return '🏦';
      case AssetType.broker:
        return '📈';
      case AssetType.crypto:
        return '₿';
      case AssetType.metal:
        return '🥇';
      case AssetType.cash:
        return '💵';
      case AssetType.other:
        return '📦';
    }
  }

  static AssetType fromString(String value) {
    return AssetType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AssetType.other,
    );
  }

  bool get supportsCashBalanceConfig =>
      this == AssetType.bank || this == AssetType.broker;

  bool get supportsMetalConfig => this == AssetType.metal;

  bool get allowsManualEntries => this != AssetType.metal;
}
