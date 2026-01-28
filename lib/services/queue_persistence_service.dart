import 'dart:developer';

import 'package:Bloomee/model/songModel.dart';
import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';

class QueuePersistenceService {
  static final QueuePersistenceService _instance =
      QueuePersistenceService._internal();
  factory QueuePersistenceService() => _instance;
  QueuePersistenceService._internal();

  /// Save the current queue to persistent storage
  Future<void> saveQueue(
    List<MediaItemModel> queue,
    int currentIndex,
    Duration position,
  ) async {
    // Check if persistence is enabled (defaulting to enabled if not set, or check settings)
    final enabled = await BloomeeDBService.getSettingBool(
            GlobalStrConsts.persistentQueueEnabled) ??
        false;
    if (!enabled) return;

    if (queue.isEmpty) return;

    // Convert to DB models
    final List<MediaItemDB> dbQueue =
        queue.map((e) => MediaItem2MediaItemDB(e)).toList();

    await BloomeeDBService.saveQueue(
      dbQueue,
      currentIndex,
      position.inMilliseconds,
    );

    log("Queue saved: ${queue.length} items, index $currentIndex",
        name: "QueuePersistenceService");
  }

  /// Load the last saved queue
  Future<(List<MediaItemModel>, int, Duration)?> loadQueue() async {
    final enabled = await BloomeeDBService.getSettingBool(
            GlobalStrConsts.persistentQueueEnabled) ??
        false;
    if (!enabled) return null;

    final savedQueue = await BloomeeDBService.loadQueue();
    if (savedQueue == null) return null;

    // Convert JSON back to MediaItemModels
    // We assume the JSON format matches MediaItemDB.toJson() -> MediaItemDB.fromJson -> MediaItemDB2MediaItem
    try {
      List<MediaItemModel> queue = [];
      for (String jsonStr in savedQueue.mediaItemsJson) {
        final dbItem = MediaItemDB.fromJson(jsonStr);
        queue.add(MediaItemDB2MediaItem(dbItem));
      }

      return (
        queue,
        savedQueue.currentIndex,
        Duration(milliseconds: savedQueue.positionMs)
      );
    } catch (e) {
      log("Error loading queue: $e", name: "QueuePersistenceService");
      return null;
    }
  }

  /// Enforce max saved queues limit/cleanup
  Future<void> cleanup() async {
    // Read setting for max queues
    final maxQueuesStr =
        await BloomeeDBService.getSettingStr(GlobalStrConsts.maxSavedQueues) ??
            "19";
    final maxQueues = int.tryParse(maxQueuesStr) ?? 19;

    await BloomeeDBService.cleanupOldQueues(maxQueues);
  }
}
