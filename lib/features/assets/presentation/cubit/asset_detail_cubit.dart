import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../domain/repositories/assets_repository.dart';
import '../../domain/entities/asset.dart';
import 'asset_detail_state.dart';

class AssetDetailCubit extends Cubit<AssetDetailState> {
  AssetDetailCubit({
    required AssetsRepository repository,
    required AnalyticsService analytics,
  }) : _repository = repository,
       _analytics = analytics,
       super(const AssetDetailInitial());

  final AssetsRepository _repository;
  final AnalyticsService _analytics;
  StreamSubscription? _entriesSub;
  String? _userId;
  String? _assetId;

  void loadDetail(String userId, String assetId, Asset asset) {
    _userId = userId;
    _assetId = assetId;
    emit(const AssetDetailLoading());
    _entriesSub?.cancel();
    _entriesSub = _repository
        .watchEntries(userId, assetId)
        .listen(
          (entries) => emit(AssetDetailLoaded(asset: asset, entries: entries)),
          onError: (e) => emit(AssetDetailError(e.toString())),
        );
  }

  Future<String?> addEntry({
    required double value,
    required DateTime recordedAt,
    String? note,
  }) async {
    if (_userId == null || _assetId == null) {
      return 'Brak kontekstu użytkownika lub aktywa.';
    }
    try {
      await _repository.addEntry(
        userId: _userId!,
        assetId: _assetId!,
        value: value,
        recordedAt: recordedAt,
        note: note,
      );
      unawaited(_analytics.logEntryAdded(assetId: _assetId!));
      return null;
    } catch (e) {
      final message = e.toString();
      if (message.contains('Wpis dla wybranej daty już istnieje')) {
        return 'Dla wybranego dnia wpis już istnieje.';
      }
      return 'Nie udało się zapisać wpisu.';
    }
  }

  Future<void> deleteEntry(String entryId) async {
    if (_userId == null || _assetId == null) return;
    try {
      await _repository.deleteEntry(_userId!, _assetId!, entryId);
      unawaited(_analytics.logEntryDeleted(assetId: _assetId!));
    } catch (e) {
      emit(AssetDetailError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _entriesSub?.cancel();
    return super.close();
  }
}
