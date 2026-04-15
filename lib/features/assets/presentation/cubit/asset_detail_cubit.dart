import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/assets_repository.dart';
import 'asset_detail_state.dart';

class AssetDetailCubit extends Cubit<AssetDetailState> {
  AssetDetailCubit({required AssetsRepository repository})
      : _repository = repository,
        super(const AssetDetailInitial());

  final AssetsRepository _repository;
  StreamSubscription? _entriesSub;
  String? _userId;
  String? _assetId;

  void loadDetail(String userId, String assetId, asset) {
    _userId = userId;
    _assetId = assetId;
    emit(const AssetDetailLoading());
    _entriesSub?.cancel();
    _entriesSub = _repository.watchEntries(userId, assetId).listen(
      (entries) => emit(AssetDetailLoaded(asset: asset, entries: entries)),
      onError: (e) => emit(AssetDetailError(e.toString())),
    );
  }

  Future<void> addEntry({
    required double value,
    required DateTime recordedAt,
    String? note,
  }) async {
    if (_userId == null || _assetId == null) return;
    try {
      await _repository.addEntry(
        userId: _userId!,
        assetId: _assetId!,
        value: value,
        recordedAt: recordedAt,
        note: note,
      );
    } catch (e) {
      emit(AssetDetailError(e.toString()));
    }
  }

  Future<void> deleteEntry(String entryId) async {
    if (_userId == null || _assetId == null) return;
    try {
      await _repository.deleteEntry(_userId!, _assetId!, entryId);
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
