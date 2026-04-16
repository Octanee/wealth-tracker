import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_config.dart';
import '../../domain/entities/asset_entry.dart';
import '../cubit/asset_detail_cubit.dart';
import '../cubit/asset_detail_state.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/add_asset_sheet.dart';
import '../widgets/asset_type_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';
import '../../../../features/dashboard/domain/calculators/wealth_calculator.dart';
import '../../../../features/market_data/domain/entities/asset_valuation.dart';
import '../../../../core/di/service_locator.dart';

class AssetDetailPage extends StatelessWidget {
  const AssetDetailPage({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = AssetDetailCubit(
          repository: ServiceLocator.instance.assetsRepository,
          analytics: ServiceLocator.instance.analyticsService,
        );
        final authState = context.read<AuthCubit>().state;
        if (authState is AuthAuthenticated) {
          cubit.loadDetail(authState.user.uid, asset.id, asset);
        }
        return cubit;
      },
      child: _AssetDetailView(asset: asset),
    );
  }
}

class _AssetDetailView extends StatelessWidget {
  const _AssetDetailView({required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: BlocBuilder<AssetDetailCubit, AssetDetailState>(
          builder: (_, state) {
            final currentAsset = state is AssetDetailLoaded
                ? state.asset
                : asset;
            return Text(currentAsset.name);
          },
        ),
        actions: [
          BlocBuilder<AssetDetailCubit, AssetDetailState>(
            builder: (context, state) {
              final currentAsset = state is AssetDetailLoaded
                  ? state.asset
                  : asset;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Edytuj aktywo',
                    onPressed: () => _showEditAsset(context, currentAsset),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.archive_outlined,
                      color: AppColors.negative,
                    ),
                    tooltip: 'Archiwizuj aktywo',
                    onPressed: () => _archiveAsset(context),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Dodaj wpis',
                    onPressed: currentAsset.type.allowsManualEntries
                        ? () => _showAddEntry(context, currentAsset)
                        : null,
                  ),
                  PopupMenuButton<_AssetDetailAction>(
                    tooltip: 'Więcej akcji',
                    onSelected: (action) async {
                      switch (action) {
                        case _AssetDetailAction.archive:
                          await _archiveAsset(context);
                        case _AssetDetailAction.delete:
                          await _deleteAsset(context);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<_AssetDetailAction>(
                        value: _AssetDetailAction.archive,
                        child: Text('Archiwizuj aktywo'),
                      ),
                      PopupMenuItem<_AssetDetailAction>(
                        value: _AssetDetailAction.delete,
                        child: Text(
                          'Usuń aktywo',
                          style: TextStyle(color: AppColors.negative),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AssetDetailCubit, AssetDetailState>(
        builder: (context, state) {
          if (state is AssetDetailLoading || state is AssetDetailInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is AssetDetailError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.negative),
              ),
            );
          }
          if (state is AssetDetailLoaded) {
            return _LoadedView(
              state: state,
              asset: state.asset,
              onAddEntry: () => _showAddEntry(context, state.asset),
              onEditEntry: (entry) =>
                  _showEditEntry(context, entry, state.asset),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddEntry(BuildContext context, Asset currentAsset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AssetDetailCubit>(),
        child: AddEntrySheet(currency: currentAsset.currency),
      ),
    );
  }

  Future<void> _showEditEntry(
    BuildContext context,
    AssetEntry entry,
    Asset currentAsset,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AssetDetailCubit>(),
        child: AddEntrySheet(
          currency: currentAsset.currency,
          initialEntry: entry,
          lockDate: true,
        ),
      ),
    );
  }

  Future<void> _showEditAsset(BuildContext context, Asset currentAsset) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddAssetSheet(
        initialAsset: currentAsset,
        onSubmit:
            ({
              required name,
              required type,
              required currency,
              required color,
              description,
              config,
            }) => context.read<AssetDetailCubit>().updateAsset(
              name: name,
              type: type,
              currency: currency,
              color: color,
              description: description,
              config: config,
            ),
      ),
    );
  }

  Future<void> _archiveAsset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archiwizować aktywo?'),
        content: const Text(
          'Aktywo zniknie z listy aktywnych, ale dane pozostaną w historii.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Archiwizuj',
              style: TextStyle(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await context.read<AssetDetailCubit>().archiveAsset();
    if (!context.mounted) return;

    if (error == null) {
      context.pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _deleteAsset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć aktywo?'),
        content: const Text(
          'Ta operacja trwale usunie aktywo oraz całą historię jego wpisów. Nie można jej cofnąć.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Usuń',
              style: TextStyle(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await context.read<AssetDetailCubit>().deleteAsset();
    if (!context.mounted) return;

    if (error == null) {
      context.pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

enum _AssetDetailAction { archive, delete }

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.state,
    required this.asset,
    required this.onAddEntry,
    required this.onEditEntry,
  });
  final AssetDetailLoaded state;
  final Asset asset;
  final VoidCallback onAddEntry;
  final ValueChanged<AssetEntry> onEditEntry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HeaderCard(state: state, asset: asset),
        ),
        if (state.entries.isNotEmpty && asset.type.allowsManualEntries) ...[
          SliverToBoxAdapter(
            child: _ChartSection(
              entries: state.entries,
              currency: asset.currency,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Historia wpisów',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _EntryTile(
                entry: state.entries[index],
                currency: asset.currency,
                onDelete: () => context.read<AssetDetailCubit>().deleteEntry(
                  state.entries[index].id,
                ),
                onEdit: () => onEditEntry(state.entries[index]),
              ),
              childCount: state.entries.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
        if (state.entries.isEmpty)
          SliverFillRemaining(
            child: _EmptyEntries(
              onAdd: onAddEntry,
              allowsManualEntries: asset.type.allowsManualEntries,
            ),
          ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.state, required this.asset});
  final AssetDetailLoaded state;
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final baseCurrency = authState is AuthAuthenticated
        ? authState.user.baseCurrency
        : asset.currency;
    final hasChange = state.changeAbsolute != null;
    final isPositive = (state.changeAbsolute ?? 0) >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: FutureBuilder<AssetValuation?>(
        future: ServiceLocator.instance.assetValuationService.valuateAsset(
          asset,
          baseCurrency: baseCurrency,
        ),
        builder: (context, valuationSnapshot) {
          final valuation = valuationSnapshot.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AssetTypeBadge(type: asset.type),
                  const Spacer(),
                  Text(
                    asset.currency,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                valuation != null
                    ? CurrencyFormatter.format(
                        valuation.nativeValue,
                        valuation.nativeCurrency,
                      )
                    : '— brak danych',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (valuation?.baseValue != null &&
                  valuation!.nativeCurrency != baseCurrency) ...[
                const SizedBox(height: 6),
                Text(
                  '≈ ${CurrencyFormatter.format(valuation.baseValue!, baseCurrency)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                _configDescription(asset),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              if (hasChange) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isPositive
                          ? AppColors.positive
                          : AppColors.negative,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      CurrencyFormatter.formatChange(
                        state.changeAbsolute!,
                        asset.currency,
                      ),
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.positive
                            : AppColors.negative,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${CurrencyFormatter.formatPercent(state.changePercent!)})',
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.positive
                            : AppColors.negative,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'vs poprzedni wpis',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              if (state.entries.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Ostatni wpis: ${DateFormatter.dateOnly(state.entries.first.recordedAt)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _configDescription(Asset asset) {
    if (asset.config case MetalAssetConfig(:final quantityGrams)) {
      return 'Złoto: ${quantityGrams.toStringAsFixed(2)} g, wycena z API NBP.';
    }
    if (asset.config case CashAssetConfig(:final cashAmount)) {
      return 'Saldo konfiguracyjne: ${CurrencyFormatter.format(cashAmount, asset.currency)}';
    }
    return asset.type.allowsManualEntries
        ? 'Bieżąca wartość wynika z ostatniego wpisu.'
        : 'Wartość aktywa jest wyliczana automatycznie.';
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.entries, required this.currency});
  final List<AssetEntry> entries;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) return const SizedBox.shrink();
    final points = WealthCalculator.toChartPoints(entries);
    final minVal = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxVal = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            'Historia wartości',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: _SimpleLineChart(
              points: points,
              minVal: minVal,
              maxVal: maxVal,
              currency: currency,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({
    required this.points,
    required this.minVal,
    required this.maxVal,
    required this.currency,
  });
  final List<ChartPoint> points;
  final double minVal;
  final double maxVal;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        points: points,
        minVal: minVal,
        maxVal: maxVal,
      ),
      child: Container(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.points,
    required this.minVal,
    required this.maxVal,
  });
  final List<ChartPoint> points;
  final double minVal;
  final double maxVal;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final range = (maxVal - minVal).abs();
    final effectiveRange = range == 0 ? 1.0 : range;

    double xStep = size.width / (points.length - 1).toDouble();
    if (points.length == 1) xStep = size.width / 2;

    Offset toOffset(int index, double value) {
      final x = points.length == 1 ? size.width / 2 : index * xStep;
      final y =
          size.height -
          ((value - minVal) / effectiveRange) * size.height * 0.85 -
          size.height * 0.075;
      return Offset(x, y);
    }

    // Gradient fill
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) {
      fillPath.lineTo(
        toOffset(i, points[i].value).dx,
        toOffset(i, points[i].value).dy,
      );
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.primary.withAlpha(80),
            AppColors.primary.withAlpha(0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final offset = toOffset(i, points[i].value);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Last point dot
    final lastOffset = toOffset(points.length - 1, points.last.value);
    canvas.drawCircle(lastOffset, 5, Paint()..color = AppColors.primary);
    canvas.drawCircle(lastOffset, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.points != points || old.minVal != minVal || old.maxVal != maxVal;
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.currency,
    required this.onDelete,
    required this.onEdit,
  });
  final AssetEntry entry;
  final String currency;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.negativeSurface,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.negative),
      ),
      confirmDismiss: (_) async => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.dateOnly(entry.recordedAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (entry.note != null && entry.note!.isNotEmpty)
                      Text(
                        entry.note!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(entry.value, currency),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              IconButton(
                tooltip: 'Usuń wpis',
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.negative,
                  size: 20,
                ),
                onPressed: () async {
                  final confirmed = await _confirmDelete(context);
                  if (confirmed == true) {
                    onDelete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń wpis?'),
        content: const Text('Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Usuń',
              style: TextStyle(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEntries extends StatelessWidget {
  const _EmptyEntries({required this.onAdd, required this.allowsManualEntries});

  final VoidCallback onAdd;
  final bool allowsManualEntries;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Brak wpisów wartości',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allowsManualEntries
                ? 'Dodaj pierwszy wpis, aby rozpocząć śledzenie.'
                : 'To aktywo jest wyceniane automatycznie na podstawie konfiguracji i kursów NBP.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (allowsManualEntries) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj wpis'),
            ),
          ],
        ],
      ),
    );
  }
}
