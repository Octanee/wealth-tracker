import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/assets_cubit.dart';
import '../cubit/assets_state.dart';
import '../../domain/entities/asset.dart';
import '../widgets/asset_tile.dart';
import '../widgets/add_asset_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  void _loadAssets() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<AssetsCubit>().loadAssets(authState.user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Moje aktywa',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'Dodaj aktywo',
            onPressed: () => _showAddAsset(context),
          ),
        ],
      ),
      body: BlocBuilder<AssetsCubit, AssetsState>(
        builder: (context, state) {
          if (state is AssetsLoading || state is AssetsInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is AssetsError) {
            return _ErrorView(message: state.message, onRetry: _loadAssets);
          }
          if (state is AssetsLoaded) {
            if (state.assets.isEmpty) {
              return _EmptyView(onAdd: () => _showAddAsset(context));
            }
            return _AssetsList(assets: state.assets);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<AssetsCubit, AssetsState>(
        builder: (context, state) {
          if (state is AssetsLoaded && state.assets.isNotEmpty) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddAsset(context),
              icon: const Icon(Icons.add),
              label: const Text('Nowe aktywo'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddAsset(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AssetsCubit>(),
        child: const AddAssetSheet(),
      ),
    );
  }
}

class _AssetsList extends StatelessWidget {
  const _AssetsList({required this.assets});
  final List<Asset> assets;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final asset = assets[index];
        return AssetTile(
          asset: asset,
          onTap: () => context.go('/assets/${asset.id}', extra: asset),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Brak aktywów',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dodaj swoje pierwsze aktywo,\naby zacząć śledzić majątek.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj pierwsze aktywo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.negative, size: 48),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Ponów')),
        ],
      ),
    );
  }
}
