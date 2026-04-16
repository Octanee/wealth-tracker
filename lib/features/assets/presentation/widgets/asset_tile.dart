import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_config.dart';
import '../../domain/entities/asset_type.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';
import '../../../../features/market_data/domain/entities/asset_valuation.dart';
import '../../../../shared/widgets/trend_badge.dart';
import 'asset_type_badge.dart';

class AssetTile extends StatelessWidget {
  const AssetTile({super.key, required this.asset, required this.onTap});

  final Asset asset;
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
    final authState = context.watch<AuthCubit>().state;
    final baseCurrency = authState is AuthAuthenticated
        ? authState.user.baseCurrency
        : asset.currency;
    final snapshot = asset.latestSnapshot;
    final previousSnapshot = asset.previousSnapshot;
    final hasValue = snapshot != null || asset.config != null;
    final hasTrend = snapshot != null && previousSnapshot != null;
    final previousValue = previousSnapshot?.value ?? 0.0;
    final change = hasTrend ? snapshot.value - previousSnapshot.value : 0.0;
    final percent = hasTrend && previousValue != 0
        ? (change / previousValue) * 100
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: FutureBuilder<AssetValuation?>(
        future: ServiceLocator.instance.assetValuationService.valuateAsset(
          asset,
          baseCurrency: baseCurrency,
        ),
        builder: (context, valuationSnapshot) {
          final valuation = valuationSnapshot.data;
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _typeColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        asset.type.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            AssetTypeBadge(type: asset.type, compact: true),
                            const SizedBox(width: 6),
                            Text(
                              asset.currency,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _secondaryLabel(asset),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        valuation != null
                            ? CurrencyFormatter.formatCompact(
                                valuation.nativeValue,
                                valuation.nativeCurrency,
                              )
                            : '—',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (valuation?.baseValue != null &&
                          valuation!.nativeCurrency != baseCurrency)
                        Text(
                          '≈ ${CurrencyFormatter.formatCompact(valuation.baseValue!, baseCurrency)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        )
                      else if (snapshot != null)
                        Text(
                          DateFormatter.relative(snapshot.recordedAt),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        )
                      else if (hasValue)
                        const Text(
                          'Wycena aktywna',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        )
                      else
                        const Text(
                          'Brak wyceny',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      if (hasTrend) ...[
                        const SizedBox(height: 6),
                        TrendBadge(
                          delta: change,
                          percent: percent,
                          currency: asset.currency,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _secondaryLabel(Asset asset) {
    if (asset.config case MetalAssetConfig(:final quantityGrams)) {
      return '${quantityGrams.toStringAsFixed(2)} g złota';
    }
    if (asset.config case CashAssetConfig(:final cashAmount)) {
      return 'Saldo: ${CurrencyFormatter.formatCompact(cashAmount, asset.currency)}';
    }
    return 'Wartość natywna aktywa';
  }
}
