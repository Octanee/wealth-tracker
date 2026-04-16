import 'package:equatable/equatable.dart';

class AssetValuation extends Equatable {
  const AssetValuation({
    required this.assetId,
    required this.nativeValue,
    required this.nativeCurrency,
    required this.baseCurrency,
    this.baseValue,
    this.effectiveDate,
    required this.isMarketDerived,
  });

  final String assetId;
  final double nativeValue;
  final String nativeCurrency;
  final String baseCurrency;
  final double? baseValue;
  final DateTime? effectiveDate;
  final bool isMarketDerived;

  bool get hasBaseValue => baseValue != null;

  @override
  List<Object?> get props => [
    assetId,
    nativeValue,
    nativeCurrency,
    baseCurrency,
    baseValue,
    effectiveDate,
    isMarketDerived,
  ];
}
