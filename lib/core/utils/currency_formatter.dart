import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double value, String currency) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;
    final formatter = NumberFormat('#,##0.##', 'pl_PL');
    final formatted = formatter.format(value);

    // Crypto/metals go after value, traditional before
    const suffixCurrencies = {
      'PLN', 'CZK', 'HUF', 'NOK', 'SEK', 'DKK',
      'BTC', 'ETH', 'XAU', 'XAG',
    };

    if (suffixCurrencies.contains(currency)) {
      return '$formatted $symbol';
    } else {
      return '$symbol$formatted';
    }
  }

  static String formatCompact(double value, String currency) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;
    String formatted;
    if (value.abs() >= 1000000) {
      formatted = '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value.abs() >= 1000) {
      formatted = '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      formatted = value.toStringAsFixed(2);
    }

    const suffixCurrencies = {
      'PLN', 'CZK', 'HUF', 'NOK', 'SEK', 'DKK',
      'BTC', 'ETH', 'XAU', 'XAG',
    };

    if (suffixCurrencies.contains(currency)) {
      return '$formatted $symbol';
    } else {
      return '$symbol$formatted';
    }
  }

  static String formatChange(double change, String currency) {
    final prefix = change >= 0 ? '+' : '';
    return '$prefix${format(change, currency)}';
  }

  static String formatPercent(double percent) {
    final prefix = percent >= 0 ? '+' : '';
    return '$prefix${percent.toStringAsFixed(2)}%';
  }
}
