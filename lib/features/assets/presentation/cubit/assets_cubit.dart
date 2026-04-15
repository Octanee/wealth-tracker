import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../domain/repositories/assets_repository.dart';
import '../../domain/entities/asset_type.dart';
import 'assets_state.dart';

class AssetsCubit extends Cubit<AssetsState> {
  AssetsCubit({
    required AssetsRepository repository,
    required AnalyticsService analytics,
  }) : _repository = repository,
       _analytics = analytics,
       super(const AssetsInitial());

  final AssetsRepository _repository;
  final AnalyticsService _analytics;
  StreamSubscription? _sub;
  String? _userId;

  void loadAssets(String userId) {
    if (_userId == userId) return; // already watching
    _userId = userId;
    emit(const AssetsLoading());
    _sub?.cancel();
    _sub = _repository
        .watchAssets(userId)
        .listen(
          (assets) => emit(AssetsLoaded(assets)),
          onError: (e) => emit(AssetsError(e.toString())),
        );
  }

  Future<void> addAsset({
    required String name,
    required AssetType type,
    required String currency,
    required String color,
    String? description,
  }) async {
    if (_userId == null) return;
    try {
      await _repository.addAsset(
        userId: _userId!,
        name: name,
        type: type,
        currency: currency,
        color: color,
        description: description,
      );
      unawaited(_analytics.logAssetCreated(assetType: type.name));
      // Stream listener will update state automatically
    } catch (e) {
      emit(AssetsError(e.toString()));
    }
  }

  Future<void> archiveAsset(String assetId) async {
    if (_userId == null) return;
    try {
      String? assetType;
      final current = state;
      if (current is AssetsLoaded) {
        for (final asset in current.assets) {
          if (asset.id == assetId) {
            assetType = asset.type.name;
            break;
          }
        }
      }
      await _repository.archiveAsset(_userId!, assetId);
      if (assetType != null) {
        unawaited(_analytics.logAssetArchived(assetType: assetType));
      }
    } catch (e) {
      emit(AssetsError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
