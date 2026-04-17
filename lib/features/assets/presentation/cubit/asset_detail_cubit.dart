import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../dashboard/domain/calculators/wealth_calculator.dart';
import '../../../market_data/domain/services/gold_history_service.dart';
import '../../domain/repositories/assets_repository.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_entry.dart';
import '../../domain/entities/asset_config.dart';
import '../../domain/entities/asset_type.dart';
import 'asset_detail_state.dart';

class AssetDetailCubit extends Cubit<AssetDetailState> {
  AssetDetailCubit({
    required AssetsRepository repository,
      required GoldHistoryService goldHistoryService,
    required AnalyticsService analytics,
  }) : _repository = repository,
      _goldHistoryService = goldHistoryService,
       _analytics = analytics,
       super(const AssetDetailInitial());

  final AssetsRepository _repository;
    final GoldHistoryService _goldHistoryService;
  final AnalyticsService _analytics;
  StreamSubscription? _entriesSub;
  String? _userId;
  String? _assetId;
  Asset? _currentAsset;

  void loadDetail(String userId, String assetId, Asset asset) {
    _userId = userId;
    _assetId = assetId;
    _currentAsset = asset;
    emit(const AssetDetailLoading());
    _entriesSub?.cancel();
    _entriesSub = _repository.watchEntries(userId, assetId).listen((entries) async {
      final sourceAsset = _currentAsset ?? asset;
      final syncedAsset = _syncSnapshots(sourceAsset, entries);
      final goldHistory = await _loadGoldHistory(syncedAsset, entries);
      _currentAsset = syncedAsset;
      emit(
        AssetDetailLoaded(
          asset: syncedAsset,
          entries: entries,
          goldHistory: goldHistory,
        ),
      );
    }, onError: (e) => emit(AssetDetailError(e.toString())));
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

    final previousState = state;
    if (previousState is AssetDetailLoaded) {
      final updatedEntries = previousState.entries
          .where((entry) => entry.id != entryId)
          .toList();
      final syncedAsset = _syncSnapshots(previousState.asset, updatedEntries);
      final goldHistory = await _loadGoldHistory(syncedAsset, updatedEntries);
      _currentAsset = syncedAsset;
      emit(
        AssetDetailLoaded(
          asset: syncedAsset,
          entries: updatedEntries,
          goldHistory: goldHistory,
        ),
      );
    }

    try {
      await _repository.deleteEntry(_userId!, _assetId!, entryId);
      unawaited(_analytics.logEntryDeleted(assetId: _assetId!));
    } catch (e) {
      if (previousState is AssetDetailLoaded) {
        _currentAsset = previousState.asset;
        emit(previousState);
      }
      emit(AssetDetailError(e.toString()));
    }
  }

  Future<String?> updateAsset({
    required String name,
    required AssetType type,
    required String currency,
    required String color,
    String? description,
    AssetConfig? config,
  }) async {
    if (_userId == null || _assetId == null) {
      return 'Brak kontekstu użytkownika lub aktywa.';
    }

    final current = state;
    if (current is! AssetDetailLoaded) {
      return 'Szczegóły aktywa nie są jeszcze gotowe.';
    }

    final updated = current.asset.copyWith(
      name: name,
      type: type,
      currency: currency,
      color: color,
      description: description,
      config: config,
      updatedAt: DateTime.now().toUtc(),
    );

    try {
      await _repository.updateAsset(_userId!, updated);
      _currentAsset = updated;
      final goldHistory = await _loadGoldHistory(updated, current.entries);
      emit(
        AssetDetailLoaded(
          asset: updated,
          entries: current.entries,
          goldHistory: goldHistory,
        ),
      );
      return null;
    } catch (_) {
      return 'Nie udało się zapisać zmian aktywa.';
    }
  }

  Asset _syncSnapshots(Asset asset, List<AssetEntry> entries) {
    if (entries.isEmpty) {
      return asset.copyWith(latestSnapshot: null, previousSnapshot: null);
    }

    final latestEntry = entries.first;
    final latestSnapshot = LatestSnapshot(
      value: latestEntry.value,
      recordedAt: latestEntry.recordedAt,
      entryId: latestEntry.id,
    );

    LatestSnapshot? previousSnapshot;
    if (entries.length > 1) {
      final previousEntry = entries[1];
      previousSnapshot = LatestSnapshot(
        value: previousEntry.value,
        recordedAt: previousEntry.recordedAt,
        entryId: previousEntry.id,
      );
    }

    return asset.copyWith(
      latestSnapshot: latestSnapshot,
      previousSnapshot: previousSnapshot,
    );
  }

  Future<List<ChartPoint>> _loadGoldHistory(
    Asset asset,
    List<AssetEntry> entries,
  ) {
    if (!asset.isGoldAsset) {
      return Future.value(const <ChartPoint>[]);
    }

    return _goldHistoryService.buildAssetHistory(
      asset: asset,
      entries: entries,
      outputCurrency: asset.currency,
    );
  }

  Future<String?> archiveAsset() async {
    if (_userId == null || _assetId == null) {
      return 'Brak kontekstu użytkownika lub aktywa.';
    }

    final current = state;
    String? assetType;
    if (current is AssetDetailLoaded) {
      assetType = current.asset.type.name;
    }

    try {
      await _repository.archiveAsset(_userId!, _assetId!);
      if (assetType != null) {
        unawaited(_analytics.logAssetArchived(assetType: assetType));
      }
      return null;
    } catch (_) {
      return 'Nie udało się zarchiwizować aktywa.';
    }
  }

  Future<String?> deleteAsset() async {
    if (_userId == null || _assetId == null) {
      return 'Brak kontekstu użytkownika lub aktywa.';
    }

    final current = state;
    String? assetType;
    if (current is AssetDetailLoaded) {
      assetType = current.asset.type.name;
    }

    try {
      await _repository.deleteAsset(_userId!, _assetId!);
      if (assetType != null) {
        unawaited(_analytics.logAssetDeleted(assetType: assetType));
      }
      return null;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return 'Brak uprawnień do usunięcia aktywa. Zaktualizuj reguły Firestore.';
      }
      return 'Nie udało się usunąć aktywa.';
    } catch (_) {
      return 'Nie udało się usunąć aktywa.';
    }
  }

  @override
  Future<void> close() {
    _entriesSub?.cancel();
    return super.close();
  }
}
