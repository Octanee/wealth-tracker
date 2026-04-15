import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/assets_repository.dart';
import '../../domain/entities/asset_type.dart';
import 'assets_state.dart';

class AssetsCubit extends Cubit<AssetsState> {
  AssetsCubit({required AssetsRepository repository})
      : _repository = repository,
        super(const AssetsInitial());

  final AssetsRepository _repository;
  StreamSubscription? _sub;
  String? _userId;

  void loadAssets(String userId) {
    if (_userId == userId) return; // already watching
    _userId = userId;
    emit(const AssetsLoading());
    _sub?.cancel();
    _sub = _repository.watchAssets(userId).listen(
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
      // Stream listener will update state automatically
    } catch (e) {
      emit(AssetsError(e.toString()));
    }
  }

  Future<void> archiveAsset(String assetId) async {
    if (_userId == null) return;
    try {
      await _repository.archiveAsset(_userId!, assetId);
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
