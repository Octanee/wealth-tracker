import '../../features/assets/domain/entities/asset_type.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'WealthLens';
  static const String defaultBaseCurrency = 'PLN';

  static const List<String> supportedCurrencies = [
    'PLN',
    'USD',
    'EUR',
    'GBP',
    'CHF',
    'JPY',
    'CZK',
    'HUF',
    'NOK',
    'SEK',
    'DKK',
    'BTC',
    'ETH',
    'XAU',
    'XAG',
  ];

  static const List<String> nbpSupportedCurrencies = [
    'PLN',
    'USD',
    'EUR',
    'GBP',
    'CHF',
    'JPY',
    'CZK',
    'HUF',
    'NOK',
    'SEK',
    'DKK',
  ];

  static List<String> currenciesForAssetType(AssetType assetType) {
    if (assetType == AssetType.bank ||
        assetType == AssetType.broker ||
        assetType == AssetType.metal) {
      return nbpSupportedCurrencies;
    }
    return supportedCurrencies;
  }

  static const Map<String, String> currencySymbols = {
    'PLN': 'zł',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'CHF': 'CHF',
    'JPY': '¥',
    'CZK': 'Kč',
    'HUF': 'Ft',
    'NOK': 'kr',
    'SEK': 'kr',
    'DKK': 'kr',
    'BTC': '₿',
    'ETH': 'Ξ',
    'XAU': 'oz Au',
    'XAG': 'oz Ag',
  };
}
