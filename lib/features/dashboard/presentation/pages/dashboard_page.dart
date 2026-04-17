import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/calculators/wealth_calculator.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/portfolio_history_chart.dart';
import '../../../../features/assets/domain/entities/asset.dart';
import '../../../../features/assets/domain/entities/asset_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';
import '../../../../features/market_data/domain/entities/asset_valuation.dart';
import '../../../../shared/widgets/trend_badge.dart';
import '../../../../features/goals/presentation/cubit/goals_cubit.dart';
import '../../../../features/goals/presentation/cubit/goals_state.dart';
import '../../../../features/goals/domain/entities/goal_type.dart';
import '../../../../features/goals/presentation/widgets/goal_progress_card.dart';
import '../../../../features/goals/presentation/widgets/add_goal_sheet.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<DashboardCubit>().loadDashboard(
        authState.user.uid,
        authState.user.baseCurrency,
      );
      context.read<GoalsCubit>().loadGoals(authState.user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final name = state is AuthAuthenticated
                ? (state.user.displayName?.split(' ').first ?? 'Witaj')
                : 'Dashboard';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Witaj, $name 👋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  DateFormatter.dateOnly(DateTime.now()),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            current is AuthAuthenticated &&
            (previous is! AuthAuthenticated ||
                previous.user.uid != current.user.uid ||
                previous.user.baseCurrency != current.user.baseCurrency),
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<DashboardCubit>().loadDashboard(
              state.user.uid,
              state.user.baseCurrency,
            );
            context.read<GoalsCubit>().loadGoals(state.user.uid);
          }
        },
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is DashboardError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.negative,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        state.message,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Odśwież'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is DashboardLoaded) {
              return _DashboardContent(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.state});
  final DashboardLoaded state;

  List<ChartPoint> get _historyWithEnoughData {
    final history = state.portfolioHistory;
    if (history == null || history.length < 2) return const [];
    return history;
  }

  List<ChartPoint> get _goldHistory {
    final history = state.goldHistory;
    if (history == null || history.isEmpty) return const [];
    return history;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBg,
      onRefresh: () async {
        final authState = context.read<AuthCubit>().state;
        if (authState is AuthAuthenticated) {
          await context.read<DashboardCubit>().reloadHistory(
            authState.user.uid,
          );
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TotalWealthSection(
                totalValue: state.totalValue,
                baseCurrency: state.baseCurrency,
                hasUnconvertedAssets: state.hasUnconvertedAssets,
              ),
              const SizedBox(height: 20),
              _PortfolioGoalsSection(
                totalValue: state.totalValue,
                baseCurrency: state.baseCurrency,
              ),
              if (_historyWithEnoughData.isNotEmpty) ...[
                RepaintBoundary(
                  child: PortfolioHistoryChart(
                    points: _historyWithEnoughData,
                    currency: state.baseCurrency,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (_goldHistory.isNotEmpty) ...[
                RepaintBoundary(
                  child: PortfolioHistoryChart(
                    points: _goldHistory,
                    currency: state.baseCurrency,
                    title: 'Historia złota',
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (state.assetsWithValue.isNotEmpty) ...[
                _AllocationSection(state: state),
                const SizedBox(height: 20),
              ],
              _AssetsSummarySection(state: state),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalWealthSection extends StatelessWidget {
  const _TotalWealthSection({
    required this.totalValue,
    required this.baseCurrency,
    required this.hasUnconvertedAssets,
  });

  final double totalValue;
  final String baseCurrency;
  final bool hasUnconvertedAssets;

  @override
  Widget build(BuildContext context) {
    if (totalValue == 0) {
      return const _EmptyDashboard();
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2753), Color(0xFF0F1729)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Łączny majątek',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(totalValue, baseCurrency),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (hasUnconvertedAssets)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Część aktywów nie została uwzględniona z powodu braku kursu NBP.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.positiveSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart, color: AppColors.positive, size: 14),
                SizedBox(width: 4),
                Text(
                  'Portfel aktywny',
                  style: TextStyle(
                    color: AppColors.positive,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
            child: const Icon(Icons.show_chart, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'Zacznij śledzić majątek',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Przejdź do zakładki Aktywa i dodaj swoje pierwsze aktywo.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/assets'),
            child: const Text('Dodaj pierwsze aktywo'),
          ),
        ],
      ),
    );
  }
}

class _AllocationSection extends StatelessWidget {
  const _AllocationSection({required this.state});
  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Alokacja portfela',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: _DonutChart(
                  assets: state.assetsWithValue,
                  percents: state.allocationPercents,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: state.assetsWithValue
                      .take(6)
                      .map(
                        (asset) => _LegendItem(
                          asset: asset,
                          percent: state.allocationPercents[asset.id] ?? 0,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.asset, required this.percent});
  final Asset asset;
  final double percent;

  Color get _color {
    const colors = [
      AppColors.assetBank,
      AppColors.assetBroker,
      AppColors.assetCrypto,
      AppColors.assetMetal,
      AppColors.assetCash,
      AppColors.assetOther,
    ];
    return colors[asset.type.index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              asset.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.assets, required this.percents});
  final List<Asset> assets;
  final Map<String, double> percents;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(assets: assets, percents: percents),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.assets, required this.percents});
  final List<Asset> assets;
  final Map<String, double> percents;

  static const _colors = [
    AppColors.assetBank,
    AppColors.assetBroker,
    AppColors.assetCrypto,
    AppColors.assetMetal,
    AppColors.assetCash,
    AppColors.assetOther,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 18.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -1.5708;
    final total = percents.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;

    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      final pct = percents[asset.id] ?? 0;
      if (pct == 0) continue;
      final sweep = (pct / total) * 6.2832;
      paint.color = _colors[asset.type.index % _colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.05,
        sweep - 0.1,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.percents != percents;
}

class _AssetsSummarySection extends StatelessWidget {
  const _AssetsSummarySection({required this.state});
  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.assets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Twoje aktywa',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/assets'),
              child: const Text(
                'Zobacz wszystkie',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(List<Asset>.from(state.assets)
              ..sort((a, b) {
                final aVal = a.latestSnapshot?.value ?? -1;
                final bVal = b.latestSnapshot?.value ?? -1;
                return bVal.compareTo(aVal);
              }))
            .take(5)
            .map(
              (asset) => _DashboardAssetRow(
                asset: asset,
                valuation: state.valuationsByAssetId[asset.id],
                baseCurrency: state.baseCurrency,
                onTap: () => context.go('/assets/${asset.id}', extra: asset),
              ),
            ),
      ],
    );
  }
}

class _DashboardAssetRow extends StatelessWidget {
  const _DashboardAssetRow({
    required this.asset,
    required this.baseCurrency,
    required this.onTap,
    this.valuation,
  });

  final Asset asset;
  final String baseCurrency;
  final AssetValuation? valuation;
  final VoidCallback onTap;

  Color get _typeColor {
    switch (asset.type) {
      case AssetType.bank:
        return AppColors.assetBank;
      case AssetType.broker:
        return AppColors.assetBroker;
      case AssetType.crypto:
        return AppColors.assetCrypto;
      case AssetType.metal:
        return AppColors.assetMetal;
      case AssetType.cash:
        return AppColors.assetCash;
      case AssetType.other:
        return AppColors.assetOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = asset.latestSnapshot;
    final previousSnapshot = asset.previousSnapshot;
    final hasTrend = snapshot != null && previousSnapshot != null;
    final previousValue = previousSnapshot?.value ?? 0.0;
    final change = hasTrend ? snapshot.value - previousSnapshot.value : 0.0;
    final percent = hasTrend && previousValue != 0
        ? (change / previousValue) * 100
        : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _typeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  asset.type.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        asset.type.displayName,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (hasTrend) ...[
                        const SizedBox(width: 8),
                        TrendBadge(
                          delta: change,
                          percent: percent,
                          currency: asset.currency,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (valuation != null || snapshot != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    valuation != null
                        ? CurrencyFormatter.formatCompact(
                            valuation!.nativeValue,
                            valuation!.nativeCurrency,
                          )
                        : CurrencyFormatter.formatCompact(
                            snapshot!.value,
                            asset.currency,
                          ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (valuation?.baseValue != null &&
                      valuation!.nativeCurrency != baseCurrency)
                    Text(
                      '≈ ${CurrencyFormatter.formatCompact(valuation!.baseValue!, baseCurrency)}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                ],
              )
            else
              const Text('—', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioGoalsSection extends StatelessWidget {
  const _PortfolioGoalsSection({
    required this.totalValue,
    required this.baseCurrency,
  });

  final double totalValue;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalsCubit, GoalsState>(
      builder: (context, state) {
        final goals = state is GoalsLoaded
            ? state.goals
                .where((g) => g.type == GoalType.portfolio)
                .toList()
            : <dynamic>[];

        if (goals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _AddGoalButton(
              label: 'Dodaj cel portfela',
              onTap: () => _openAddGoal(context),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cele portfela',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openAddGoal(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Dodaj cel'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...goals.map(
                (goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GoalProgressCard(
                    goal: goal,
                    currentValue: totalValue,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAddGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<GoalsCubit>(),
        child: AddGoalSheet(
          goalType: GoalType.portfolio,
          targetCurrency: baseCurrency,
        ),
      ),
    );
  }
}

class _AddGoalButton extends StatelessWidget {
  const _AddGoalButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withAlpha(80),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
