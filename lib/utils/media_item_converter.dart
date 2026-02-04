import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:audio_service/audio_service.dart';

class MediaItemConverter {
  static MediaItem dbToMediaItem(MediaItemDB dbItem) {
    return MediaItem(
      id: dbItem.mediaID,
      album: dbItem.album,
      title: dbItem.title,
      artist: dbItem.artist,
      artUri: Uri.parse(dbItem.artURL),
      duration:
          dbItem.duration != null ? Duration(seconds: dbItem.duration!) : null,
      extras: {
        'url': dbItem.streamingURL,
        'perma_url': dbItem.permaURL,
        'source': dbItem.source,
        'lang': dbItem.language,
      },
    );
  }

  static List<MediaItem> dbListToMediaItemList(List<MediaItemDB> dbList) {
    return dbList.map((e) => dbToMediaItem(e)).toList();
  }
}
