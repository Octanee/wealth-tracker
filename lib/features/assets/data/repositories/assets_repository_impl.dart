import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_entry.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/repositories/assets_repository.dart';
import '../models/asset_model.dart';
import '../models/asset_entry_model.dart';

class AssetsRepositoryImpl implements AssetsRepository {
  AssetsRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference _assetsCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('assets');

  CollectionReference _entriesCol(String userId, String assetId) =>
      _assetsCol(userId).doc(assetId).collection('entries');

  @override
  Stream<List<Asset>> watchAssets(String userId) {
    return _assetsCol(userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AssetModel.fromFirestore(d).toDomain()).toList());
  }

  @override
  Future<List<Asset>> getAssets(String userId) async {
    final snap = await _assetsCol(userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map((d) => AssetModel.fromFirestore(d).toDomain()).toList();
  }

  @override
  Future<Asset> addAsset({
    required String userId,
    required String name,
    required AssetType type,
    required String currency,
    required String color,
    String? description,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final model = AssetModel(
      id: id,
      name: name,
      type: type.name,
      currency: currency,
      color: color,
      description: description,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
    await _assetsCol(userId).doc(id).set(model.toFirestore());
    return model.toDomain();
  }

  @override
  Future<void> archiveAsset(String userId, String assetId) async {
    await _assetsCol(userId).doc(assetId).update({
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateAsset(String userId, Asset asset) async {
    await _assetsCol(userId).doc(asset.id).update({
      'name': asset.name,
      'type': asset.type.name,
      'currency': asset.currency,
      'color': asset.color,
      'description': asset.description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AssetEntry>> watchEntries(String userId, String assetId) {
    return _entriesCol(userId, assetId)
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AssetEntryModel.fromFirestore(d, assetId).toDomain())
            .toList());
  }

  @override
  Future<List<AssetEntry>> getEntries(String userId, String assetId) async {
    final snap = await _entriesCol(userId, assetId)
        .orderBy('recordedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => AssetEntryModel.fromFirestore(d, assetId).toDomain())
        .toList();
  }

  @override
  Future<AssetEntry> addEntry({
    required String userId,
    required String assetId,
    required double value,
    required DateTime recordedAt,
    String? note,
  }) async {
    final entryId = _uuid.v4();
    final now = DateTime.now().toUtc();
    final model = AssetEntryModel(
      id: entryId,
      assetId: assetId,
      value: value,
      note: note,
      recordedAt: recordedAt,
      createdAt: now,
    );

    // Batch: write entry + update latestSnapshot on asset atomically
    final batch = _firestore.batch();
    final entryRef = _entriesCol(userId, assetId).doc(entryId);
    batch.set(entryRef, model.toFirestore());

    // Update latestSnapshot only if this entry is newer than existing snapshot
    final assetDoc = await _assetsCol(userId).doc(assetId).get();
    final assetData = assetDoc.data() as Map<String, dynamic>?;
    final existingSnapshot = assetData?['latestSnapshot'] as Map<String, dynamic>?;
    final existingDate = existingSnapshot != null
        ? (existingSnapshot['recordedAt'] as Timestamp).toDate()
        : null;

    if (existingDate == null || recordedAt.isAfter(existingDate) ||
        recordedAt.isAtSameMomentAs(existingDate)) {
      batch.update(_assetsCol(userId).doc(assetId), {
        'latestSnapshot': {
          'value': value,
          'recordedAt': Timestamp.fromDate(recordedAt),
          'entryId': entryId,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return model.toDomain();
  }

  @override
  Future<void> deleteEntry(String userId, String assetId, String entryId) async {
    await _entriesCol(userId, assetId).doc(entryId).delete();

    // Recalculate latestSnapshot
    final snap = await _entriesCol(userId, assetId)
        .orderBy('recordedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      await _assetsCol(userId).doc(assetId).update({
        'latestSnapshot': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final latest = snap.docs.first;
      final data = latest.data() as Map<String, dynamic>;
      await _assetsCol(userId).doc(assetId).update({
        'latestSnapshot': {
          'value': data['value'],
          'recordedAt': data['recordedAt'],
          'entryId': latest.id,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
