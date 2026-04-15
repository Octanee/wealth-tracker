import 'package:flutter/material.dart';
import '../../domain/entities/asset_type.dart';
import '../../../../core/theme/app_colors.dart';

class AssetTypeBadge extends StatelessWidget {
  const AssetTypeBadge({super.key, required this.type, this.compact = false});

  final AssetType type;
  final bool compact;

  Color get _color {
    switch (type) {
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Text(
        compact ? type.name.toUpperCase() : type.displayName,
        style: TextStyle(
          color: _color,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: compact ? 0.5 : 0,
        ),
      ),
    );
  }
}
