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

  Future<void> _recalculateSnapshots(String userId, String assetId) async {
    final snap = await _entriesCol(
      userId,
      assetId,
    ).orderBy('recordedAt', descending: true).limit(2).get();

    if (snap.docs.isEmpty) {
      await _assetsCol(userId).doc(assetId).update({
        'latestSnapshot': null,
        'previousSnapshot': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final latest = snap.docs.first;
    final latestData = latest.data() as Map<String, dynamic>;
    Map<String, dynamic>? previousSnapshot;
    if (snap.docs.length > 1) {
      final previous = snap.docs[1];
      final previousData = previous.data() as Map<String, dynamic>;
      previousSnapshot = {
        'value': previousData['value'],
        'recordedAt': previousData['recordedAt'],
        'entryId': previous.id,
      };
    }

    await _assetsCol(userId).doc(assetId).update({
      'latestSnapshot': {
        'value': latestData['value'],
        'recordedAt': latestData['recordedAt'],
        'entryId': latest.id,
      },
      'previousSnapshot': previousSnapshot,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Asset>> watchAssets(String userId) {
    return _assetsCol(userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AssetModel.fromFirestore(d).toDomain())
              .toList(),
        );
  }

  @override
  Future<List<Asset>> getAssets(String userId) async {
    final snap = await _assetsCol(userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs
        .map((d) => AssetModel.fromFirestore(d).toDomain())
        .toList();
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
        .map(
          (snap) => snap.docs
              .map((d) => AssetEntryModel.fromFirestore(d, assetId).toDomain())
              .toList(),
        );
  }

  @override
  Future<List<AssetEntry>> getEntries(String userId, String assetId) async {
    final snap = await _entriesCol(
      userId,
      assetId,
    ).orderBy('recordedAt', descending: true).get();
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
    final dayStart = DateTime(
      recordedAt.year,
      recordedAt.month,
      recordedAt.day,
    );
    final nextDayStart = dayStart.add(const Duration(days: 1));

    final existingForDay = await _entriesCol(userId, assetId)
        .where(
          'recordedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
          isLessThan: Timestamp.fromDate(nextDayStart),
        )
        .limit(1)
        .get();

    if (existingForDay.docs.isNotEmpty) {
      final existing = existingForDay.docs.first;
      final existingData = existing.data() as Map<String, dynamic>;
      final updatePayload = <String, Object?>{
        'value': value,
        'recordedAt': Timestamp.fromDate(recordedAt),
      };
      final trimmedNote = note?.trim();
      if (trimmedNote != null && trimmedNote.isNotEmpty) {
        updatePayload['note'] = trimmedNote;
      } else {
        updatePayload['note'] = FieldValue.delete();
      }

      await existing.reference.update(updatePayload);
      await _recalculateSnapshots(userId, assetId);

      return AssetEntryModel(
        id: existing.id,
        assetId: assetId,
        value: value,
        note: trimmedNote,
        recordedAt: recordedAt,
        createdAt: (existingData['createdAt'] as Timestamp).toDate(),
      ).toDomain();
    }

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

    final entryRef = _entriesCol(userId, assetId).doc(entryId);
    await entryRef.set(model.toFirestore());
    await _recalculateSnapshots(userId, assetId);
    return model.toDomain();
  }

  @override
  Future<void> deleteEntry(
    String userId,
    String assetId,
    String entryId,
  ) async {
    await _entriesCol(userId, assetId).doc(entryId).delete();
    await _recalculateSnapshots(userId, assetId);
  }
}
