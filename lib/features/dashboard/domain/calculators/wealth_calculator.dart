import '../../../assets/domain/entities/asset.dart';
import '../../../assets/domain/entities/asset_entry.dart';

class WealthCalculator {
  const WealthCalculator._();

  /// Sums the latest known values of all assets.
  /// Note: Values are in their native currency — no FX conversion in MVP.
  /// Groups by currency and returns per-currency totals.
  static Map<String, double> totalByCurrency(List<Asset> assets) {
    final totals = <String, double>{};
    for (final asset in assets) {
      if (asset.latestSnapshot == null) continue;
      totals[asset.currency] =
          (totals[asset.currency] ?? 0) + asset.latestSnapshot!.value;
    }
    return totals;
  }

  /// Returns allocation percentage for each asset relative to its currency group.
  static Map<String, double> allocationPercents(List<Asset> assets) {
    final totals = totalByCurrency(assets);
    final result = <String, double>{};
    for (final asset in assets) {
      if (asset.latestSnapshot == null) continue;
      final total = totals[asset.currency] ?? 0;
      result[asset.id] = total == 0 ? 0 : (asset.latestSnapshot!.value / total) * 100;
    }
    return result;
  }

  /// Overall portfolio trend based on entries sorted by recordedAt ASC.
  static TrendDirection trend(List<AssetEntry> entries) {
    if (entries.length < 2) return TrendDirection.neutral;
    // entries are stored DESC, so last = oldest
    final recent = entries.first.value;
    final older = entries.last.value;
    if (recent > older) return TrendDirection.up;
    if (recent < older) return TrendDirection.down;
    return TrendDirection.neutral;
  }

  /// Returns [value, date] pairs for chart from entry list (DESC → reversed to ASC).
  static List<ChartPoint> toChartPoints(List<AssetEntry> entries) {
    final ascending = entries.reversed.toList();
    return ascending
        .map((e) => ChartPoint(date: e.recordedAt, value: e.value))
        .toList();
  }

  /// Change between last two entries.
  static EntryChange? lastChange(List<AssetEntry> entries) {
    if (entries.length < 2) return null;
    final latest = entries[0].value;
    final previous = entries[1].value;
    final delta = latest - previous;
    final percent = previous == 0 ? 0.0 : (delta / previous) * 100;
    return EntryChange(delta: delta, percent: percent);
  }
}

enum TrendDirection { up, down, neutral }

class ChartPoint {
  const ChartPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}

class EntryChange {
  const EntryChange({required this.delta, required this.percent});
  final double delta;
  final double percent;
  bool get isPositive => delta >= 0;
}
