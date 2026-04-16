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
}
