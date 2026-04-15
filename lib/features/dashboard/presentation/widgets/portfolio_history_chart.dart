import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/calculators/wealth_calculator.dart';

enum _TimeRange {
  month1('1M', 30),
  month3('3M', 90),
  month6('6M', 180),
  year1('1R', 365),
  all('Wszystko', -1);

  const _TimeRange(this.label, this.days);
  final String label;
  final int days;
}

class PortfolioHistoryChart extends StatefulWidget {
  const PortfolioHistoryChart({
    super.key,
    required this.points,
    required this.currency,
  });

  final List<ChartPoint> points;
  final String currency;

  @override
  State<PortfolioHistoryChart> createState() => _PortfolioHistoryChartState();
}

class _PortfolioHistoryChartState extends State<PortfolioHistoryChart> {
  _TimeRange _range = _TimeRange.all;

  List<ChartPoint> get _filtered {
    if (_range == _TimeRange.all || widget.points.isEmpty) {
      return widget.points;
    }
    final cutoff = DateTime.now().subtract(Duration(days: _range.days));
    final filtered =
        widget.points.where((p) => p.date.isAfter(cutoff)).toList();
    return filtered.isEmpty ? widget.points.take(1).toList() : filtered;
  }

  List<_TimeRange> get _availableRanges {
    if (widget.points.isEmpty) return [_TimeRange.all];
    final oldest = widget.points.first.date;
    final spanDays = DateTime.now().difference(oldest).inDays;
    return _TimeRange.values
        .where((r) => r == _TimeRange.all || r.days <= spanDays + 7)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final points = _filtered;
    final last = points.isNotEmpty ? points.last.value : 0.0;
    final first = points.isNotEmpty ? points.first.value : 0.0;
    final delta = last - first;
    final percent = first == 0 ? 0.0 : (delta / first) * 100;
    final isPositive = delta >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historia portfela (${widget.currency})',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(last, widget.currency),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (points.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppColors.positiveSurface
                        : AppColors.negativeSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: isPositive
                            ? AppColors.positive
                            : AppColors.negative,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${CurrencyFormatter.formatChange(delta, widget.currency)}'
                        ' (${CurrencyFormatter.formatPercent(percent)})',
                        style: TextStyle(
                          color: isPositive
                              ? AppColors.positive
                              : AppColors.negative,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: _buildChart(points)),
          const SizedBox(height: 12),
          _RangeSelector(
            selected: _range,
            available: _availableRanges,
            onSelected: (r) => setState(() => _range = r),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<ChartPoint> points) {
    if (points.length < 2) {
      return const Center(
        child: Text(
          'Za mało danych dla tego zakresu',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    final spots = points
        .map(
          (p) => FlSpot(
            p.date.millisecondsSinceEpoch.toDouble(),
            p.value,
          ),
        )
        .toList();

    final values = points.map((p) => p.value).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final yPadding = maxY == minY ? maxY * 0.1 + 1 : (maxY - minY) * 0.15;
    final yInterval = maxY == minY ? 1.0 : (maxY - minY) / 4;

    final firstMs = spots.first.x;
    final lastMs = spots.last.x;
    final xInterval = lastMs == firstMs ? 1.0 : (lastMs - firstMs) / 4;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.divider,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: xInterval,
              getTitlesWidget: _bottomTitleWidget,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: _leftTitleWidget,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: points.length <= 14,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(55),
                  AppColors.primary.withAlpha(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final date = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
              return LineTooltipItem(
                '${DateFormatter.dateOnly(date)}\n',
                const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                children: [
                  TextSpan(
                    text: CurrencyFormatter.format(s.y, widget.currency),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _bottomTitleWidget(double value, TitleMeta meta) {
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        DateFormatter.monthYear(date),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      ),
    );
  }

  Widget _leftTitleWidget(double value, TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        CurrencyFormatter.formatCompact(value, widget.currency),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        textAlign: TextAlign.right,
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selected,
    required this.available,
    required this.onSelected,
  });

  final _TimeRange selected;
  final List<_TimeRange> available;
  final ValueChanged<_TimeRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: available.map((range) {
        final isSelected = range == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onSelected(range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                range.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
