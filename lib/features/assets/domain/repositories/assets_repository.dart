import '../entities/asset.dart';
import '../entities/asset_entry.dart';
import '../entities/asset_type.dart';

abstract class AssetsRepository {
  /// Streams list of non-archived assets for real-time updates
  Stream<List<Asset>> watchAssets(String userId);

  /// One-shot fetch (used for dashboard refresh)
  Future<List<Asset>> getAssets(String userId);

  /// Add new asset — returns created asset with generated ID
  Future<Asset> addAsset({
    required String userId,
    required String name,
    required AssetType type,
    required String currency,
    required String color,
    String? description,
  });

  /// Archive asset (soft delete)
  Future<void> archiveAsset(String userId, String assetId);

  /// Update asset metadata
  Future<void> updateAsset(String userId, Asset asset);

  // ─── Entries (value history) — separated from asset metadata ───

  /// Stream entry history for one asset, ordered by recordedAt DESC
  Stream<List<AssetEntry>> watchEntries(String userId, String assetId);

  /// One-shot fetch of entries
  Future<List<AssetEntry>> getEntries(String userId, String assetId);

  /// Add value entry — also updates latestSnapshot on parent asset atomically
  Future<AssetEntry> addEntry({
    required String userId,
    required String assetId,
    required double value,
    required DateTime recordedAt,
    String? note,
  });

  /// Delete a single entry — recalculates latestSnapshot if needed
  Future<void> deleteEntry(String userId, String assetId, String entryId);

  /// Bulk fetch of all entries for multiple assets.
  /// Returns assetId → entries sorted by recordedAt ASC (oldest first).
  Future<Map<String, List<AssetEntry>>> getAllEntries(
    String userId,
    List<String> assetIds,
  );
}
