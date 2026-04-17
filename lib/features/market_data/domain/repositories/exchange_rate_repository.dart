abstract class ExchangeRateRepository {
  Future<double?> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  });

  Future<double?> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  });

  Future<double?> getGoldPricePerGram({DateTime? date});

  Future<Map<DateTime, double>> getGoldPriceSeriesPerGram({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Returns a time series of PLN mid-rates for [currencyCode] from
  /// [startDate] to [endDate]. Dates are normalized to UTC midnight.
  /// Only business days with published rates are included; callers should
  /// forward-fill for missing dates.
  Future<Map<DateTime, double>> getExchangeRateSeriesToPln({
    required String currencyCode,
    required DateTime startDate,
    required DateTime endDate,
  });
}
