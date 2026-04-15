class AppConstants {
  AppConstants._();

  static const String appName = 'WealthLens';
  static const String defaultBaseCurrency = 'PLN';

  static const List<String> supportedCurrencies = [
    'PLN', 'USD', 'EUR', 'GBP', 'CHF', 'JPY',
    'CZK', 'HUF', 'NOK', 'SEK', 'DKK',
    'BTC', 'ETH', 'XAU', 'XAG',
  ];

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
