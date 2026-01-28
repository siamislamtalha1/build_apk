import 'package:Bloomee/model/songModel.dart';
import 'package:Bloomee/model/time_period.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:isar_community/isar.dart';

class StatisticsDBService {
  static Future<Isar> get db => BloomeeDBService.db;

  /// Increments play count for a song, artist, and album
  static Future<void> incrementPlayCount(MediaItemModel song) async {
    final isar = await db;
    // We only track song level stats directly in Isar for now
    // Aggregation for artists/albums can be done on the fly or via similar DB entries

    // Check if entry exists
    final existingStat = await isar.playStatisticsDBs
        .filter()
        .mediaIdEqualTo(song.id.toString())
        .findFirst();

    if (existingStat != null) {
      await isar.writeTxn(() async {
        existingStat.playCount += 1;
        existingStat.lastPlayed = DateTime.now();
        List<DateTime> timestamps = existingStat.playTimestamps.toList();
        timestamps.add(DateTime.now());
        existingStat.playTimestamps = timestamps;
        await isar.playStatisticsDBs.put(existingStat);
      });
    } else {
      final newStat = PlayStatisticsDB(
        mediaId: song.id.toString(),
        title: song.title,
        artist: song.artist ?? "",
        album: song.album ?? "",
        playCount: 1,
        lastPlayed: DateTime.now(),
        playTimestamps: [DateTime.now()],
      );
      await isar.writeTxn(() async {
        await isar.playStatisticsDBs.put(newStat);
      });
    }
  }

  /// Get top songs filtered by time period
  static Future<List<PlayStatisticsDB>> getTopSongs({
    TimePeriod period = TimePeriod.allTime,
    int limit = 50,
  }) async {
    final isar = await db;

    if (period == TimePeriod.allTime) {
      return isar.playStatisticsDBs
          .where()
          .sortByPlayCountDesc()
          .limit(limit)
          .findAll();
    }

    // For specific time periods, we need to filter timestamps
    // Isar doesn't easily support "count items in list field where condition" in query
    // So we fetch candidates and process in Dart (or advanced Isar query if possible)
    // Optimization: Filter by lastPlayed > start_date first

    final startDate = TimePeriodHelper.getStartDate(period);

    // Get all items played at least once since startDate
    final candidates = await isar.playStatisticsDBs
        .filter()
        .lastPlayedGreaterThan(startDate)
        .findAll();

    // Calculate effective play count for the period
    final List<MapEntry<PlayStatisticsDB, int>> scored = [];

    for (var stat in candidates) {
      int count = stat.playTimestamps.where((t) => t.isAfter(startDate)).length;
      if (count > 0) {
        scored.add(MapEntry(stat, count));
      }
    }

    // Sort by calculated count
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(limit).map((e) => e.key).toList();
  }

  // Artists and Albums would typically need their own tables or aggregation
  // For MVP, we can aggregate from Song statistics

  static Future<List<Map<String, dynamic>>> getTopArtists({
    TimePeriod period = TimePeriod.allTime,
    int limit = 20,
  }) async {
    // Determine cutoff
    final startDate = period == TimePeriod.allTime
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : TimePeriodHelper.getStartDate(period);

    final isar = await db;

    // Fetch all relevant stats
    final stats = await isar.playStatisticsDBs
        .filter()
        .lastPlayedGreaterThan(startDate)
        .findAll();

    // Aggregate
    final Map<String, int> artistCounts = {};
    // Also keep one sample song metadata for image if needed (not stored in stats yet)

    for (var stat in stats) {
      int count = 0;
      if (period == TimePeriod.allTime) {
        count = stat.playCount;
      } else {
        count = stat.playTimestamps.where((t) => t.isAfter(startDate)).length;
      }

      if (count > 0) {
        artistCounts.update(stat.artist, (value) => value + count,
            ifAbsent: () => count);
      }
    }

    // Sort
    final sortedEntries = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(limit)
        .map((e) => {"artist": e.key, "count": e.value})
        .toList();
  }
}
