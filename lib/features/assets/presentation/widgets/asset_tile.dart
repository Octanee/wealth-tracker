import 'package:flutter/material.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import 'asset_type_badge.dart';

class AssetTile extends StatelessWidget {
  const AssetTile({super.key, required this.asset, required this.onTap});

  final Asset asset;
  final VoidCallback onTap;

  Color get _typeColor {
    switch (asset.type) {
      case AssetType.bank:   return AppColors.assetBank;
      case AssetType.broker: return AppColors.assetBroker;
      case AssetType.crypto: return AppColors.assetCrypto;
      case AssetType.metal:  return AppColors.assetMetal;
      case AssetType.cash:   return AppColors.assetCash;
      case AssetType.other:  return AppColors.assetOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = asset.latestSnapshot;
    final hasValue = snapshot != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
              // Type icon circle
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
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasValue
                        ? CurrencyFormatter.formatCompact(snapshot.value, asset.currency)
                        : '—',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (hasValue)
                    Text(
                      DateFormatter.relative(snapshot.recordedAt),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    )
                  else
                    const Text(
                      'Brak wpisów',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
