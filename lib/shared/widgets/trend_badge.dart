import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class TrendBadge extends StatelessWidget {
  const TrendBadge({
    super.key,
    required this.delta,
    required this.percent,
    required this.currency,
    this.compact = false,
  });

  final double delta;
  final double percent;
  final String currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final fg = isPositive ? AppColors.positive : AppColors.negative;
    final bg = isPositive
        ? AppColors.positiveSurface
        : AppColors.negativeSurface;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: compact ? 12 : 14,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            compact
                ? CurrencyFormatter.formatPercent(percent)
                : '${CurrencyFormatter.formatChange(delta, currency)} (${CurrencyFormatter.formatPercent(percent)})',
            style: TextStyle(
              color: fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
