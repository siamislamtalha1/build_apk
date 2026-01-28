export 'package:Bloomee/services/db/GlobalDB.dart' show PlayStatisticsDB;

// We can add non-persisted UI view models here if needed in the future
class PlayStatisticsModel {
  final String title;
  final String artist;
  final String album;
  final int playCount;

  PlayStatisticsModel({
    required this.title,
    required this.artist,
    required this.album,
    required this.playCount,
  });
}
