import '../../../assets/domain/entities/asset.dart';
import '../../../assets/domain/entities/asset_config.dart';
import '../../../assets/domain/entities/asset_type.dart';
import '../entities/asset_valuation.dart';
import '../repositories/exchange_rate_repository.dart';

class AssetValuationService {
  AssetValuationService({required ExchangeRateRepository ratesRepository})
    : _ratesRepository = ratesRepository;

  final ExchangeRateRepository _ratesRepository;

  Future<AssetValuation?> valuateAsset(
    Asset asset, {
    required String baseCurrency,
    DateTime? asOfDate,
  }) async {
    final nativeValue = await resolveNativeValue(asset, asOfDate: asOfDate);
    if (nativeValue == null) {
      return null;
    }

    final baseValue = await _ratesRepository.convert(
      amount: nativeValue,
      fromCurrency: asset.currency,
      toCurrency: baseCurrency,
      date: asOfDate,
    );

    return AssetValuation(
      assetId: asset.id,
      nativeValue: nativeValue,
      nativeCurrency: asset.currency,
      baseCurrency: baseCurrency,
      baseValue: baseValue,
      effectiveDate: asOfDate ?? asset.latestSnapshot?.recordedAt,
      isMarketDerived: asset.type == AssetType.metal,
    );
  }

  Future<double?> convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    DateTime? asOfDate,
  }) {
    return _ratesRepository.convert(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      date: asOfDate,
    );
  }

  Future<Map<DateTime, double>> getGoldPriceSeriesPerGram({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _ratesRepository.getGoldPriceSeriesPerGram(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<double?> resolveNativeValue(Asset asset, {DateTime? asOfDate}) async {
    if (asset.config case MetalAssetConfig(
      :final metalType,
      :final quantityGrams,
    )) {
      if (metalType != PreciousMetalType.gold) {
        return null;
      }
      final currentQuantityGrams = asset.latestSnapshot?.value ?? quantityGrams;
      final goldPricePln = await _ratesRepository.getGoldPricePerGram(
        date: asOfDate,
      );
      if (goldPricePln == null) return null;
      final valueInPln = goldPricePln * currentQuantityGrams;
      if (asset.currency == 'PLN') {
        return valueInPln;
      }
      return _ratesRepository.convert(
        amount: valueInPln,
        fromCurrency: 'PLN',
        toCurrency: asset.currency,
        date: asOfDate,
      );
    }

    if (asset.latestSnapshot != null) {
      return asset.latestSnapshot!.value;
    }

    if (asset.config case CashAssetConfig(:final cashAmount)) {
      return cashAmount;
    }

    return null;
  }
}
