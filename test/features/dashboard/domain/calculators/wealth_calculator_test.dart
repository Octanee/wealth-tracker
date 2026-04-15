import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/features/assets/domain/entities/asset.dart';
import 'package:wealthlens/features/assets/domain/entities/asset_entry.dart';
import 'package:wealthlens/features/assets/domain/entities/asset_type.dart';
import 'package:wealthlens/features/dashboard/domain/calculators/wealth_calculator.dart';

void main() {
  group('WealthCalculator.totalByCurrency', () {
    test('sums latest snapshots per currency', () {
      final assets = [
        _asset(
          id: 'a1',
          currency: 'PLN',
          latest: LatestSnapshot(
            value: 1000,
            recordedAt: _d(2026, 4, 10),
            entryId: 'e1',
          ),
        ),
        _asset(
          id: 'a2',
          currency: 'PLN',
          latest: LatestSnapshot(
            value: 500,
            recordedAt: _d(2026, 4, 11),
            entryId: 'e2',
          ),
        ),
        _asset(
          id: 'a3',
          currency: 'USD',
          latest: LatestSnapshot(
            value: 250,
            recordedAt: _d(2026, 4, 11),
            entryId: 'e3',
          ),
        ),
        _asset(id: 'a4', currency: 'EUR', latest: null),
      ];

      final totals = WealthCalculator.totalByCurrency(assets);

      expect(totals['PLN'], 1500);
      expect(totals['USD'], 250);
      expect(totals.containsKey('EUR'), isFalse);
    });
  });

  group('WealthCalculator.allocationPercents', () {
    test('calculates allocation inside each currency bucket', () {
      final assets = [
        _asset(
          id: 'a1',
          currency: 'PLN',
          latest: LatestSnapshot(
            value: 150,
            recordedAt: _d(2026, 4, 1),
            entryId: 'e1',
          ),
        ),
        _asset(
          id: 'a2',
          currency: 'PLN',
          latest: LatestSnapshot(
            value: 50,
            recordedAt: _d(2026, 4, 1),
            entryId: 'e2',
          ),
        ),
      ];

      final alloc = WealthCalculator.allocationPercents(assets);

      expect(alloc['a1'], closeTo(75, 0.0001));
      expect(alloc['a2'], closeTo(25, 0.0001));
    });
  });

  group('WealthCalculator.lastChange', () {
    test('returns delta and percent from two newest entries', () {
      final entries = [
        _entry(id: 'n', value: 1200, recordedAt: _d(2026, 4, 11)),
        _entry(id: 'o', value: 1000, recordedAt: _d(2026, 4, 10)),
      ];

      final change = WealthCalculator.lastChange(entries);

      expect(change, isNotNull);
      expect(change!.delta, 200);
      expect(change.percent, 20);
      expect(change.isPositive, isTrue);
    });

    test('returns null for less than two entries', () {
      final change = WealthCalculator.lastChange([
        _entry(id: 'n', value: 1000, recordedAt: _d(2026, 4, 11)),
      ]);

      expect(change, isNull);
    });
  });

  group('WealthCalculator.trend', () {
    test('returns up when newest is greater than oldest', () {
      final entries = [
        _entry(id: 'new', value: 10, recordedAt: _d(2026, 4, 11)),
        _entry(id: 'old', value: 5, recordedAt: _d(2026, 4, 1)),
      ];

      expect(WealthCalculator.trend(entries), TrendDirection.up);
    });

    test('returns neutral for less than two entries', () {
      expect(
        WealthCalculator.trend([
          _entry(id: 'only', value: 10, recordedAt: _d(2026, 4, 11)),
        ]),
        TrendDirection.neutral,
      );
    });
  });

  group('WealthCalculator.toChartPoints', () {
    test('returns points in ascending date order', () {
      final entriesDesc = [
        _entry(id: 'e2', value: 200, recordedAt: _d(2026, 4, 2)),
        _entry(id: 'e1', value: 100, recordedAt: _d(2026, 4, 1)),
      ];

      final points = WealthCalculator.toChartPoints(entriesDesc);

      expect(points.length, 2);
      expect(points.first.date, _d(2026, 4, 1));
      expect(points.first.value, 100);
      expect(points.last.date, _d(2026, 4, 2));
      expect(points.last.value, 200);
    });
  });
}

Asset _asset({
  required String id,
  required String currency,
  required LatestSnapshot? latest,
}) {
  return Asset(
    id: id,
    name: id,
    type: AssetType.other,
    currency: currency,
    color: '#4F6EF7',
    isArchived: false,
    createdAt: _d(2026, 1, 1),
    updatedAt: _d(2026, 1, 1),
    latestSnapshot: latest,
    previousSnapshot: null,
  );
}

AssetEntry _entry({
  required String id,
  required double value,
  required DateTime recordedAt,
}) {
  return AssetEntry(
    id: id,
    assetId: 'asset',
    value: value,
    recordedAt: recordedAt,
    createdAt: recordedAt,
  );
}

DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);
