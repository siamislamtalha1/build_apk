import 'dart:developer';
import 'package:Bloomee/model/songModel.dart';
import 'package:Bloomee/model/saavnModel.dart';
import 'package:Bloomee/repository/Youtube/youtube_api.dart';
import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/screens/widgets/snackbar.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/utils/ytstream_source.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioSourceManager {
  // AudioSourceManager without audio source caching

  Future<AudioSource> getAudioSource(MediaItem mediaItem) async {
    try {
      // Check for offline version first
      final down = await BloomeeDBService.getDownloadDB(
          mediaItem2MediaItemModel(mediaItem));
      if (down != null) {
        log("Playing Offline: ${mediaItem.title}", name: "AudioSourceManager");
        SnackbarService.showMessage("Playing Offline",
            duration: const Duration(seconds: 1));

        final audioSource = AudioSource.uri(
            Uri.file('${down.filePath}/${down.fileName}'),
            tag: mediaItem);
        return audioSource;
      }

      AudioSource audioSource;

      final sourceStr = (mediaItem.extras?["source"] ?? '').toString().toLowerCase();
      final isYoutube = sourceStr == 'youtube' || sourceStr.contains('yt') ||
          (mediaItem.extras?["perma_url"]?.toString().toLowerCase().contains('youtube') ?? false);

      if (isYoutube) {
        String? quality =
            await BloomeeDBService.getSettingStr(GlobalStrConsts.ytStrmQuality);
        quality = quality ?? "high";
        quality = quality.toLowerCase();
        final id = mediaItem.id.replaceAll("youtube", '');

        // Prefer direct URL playback for YouTube. This is generally more stable
        // across platforms than StreamAudioSource (reduces idle/flicker loops).
        try {
          final yt = YouTubeServices();
          final refreshed = await yt.refreshLink(id, quality: 'Low');
          if (refreshed != null && refreshed['qurls'] is List) {
            final qurls = refreshed['qurls'] as List;
            final int idx = (quality == 'high') ? 2 : 1;
            final url = (qurls.length > idx) ? qurls[idx]?.toString() : null;
            if (url != null && url.isNotEmpty) {
              audioSource = AudioSource.uri(Uri.parse(url), tag: mediaItem);
            } else {
              throw Exception('Empty YouTube stream URL');
            }
          } else {
            throw Exception('Failed to refresh YouTube stream URL');
          }
        } catch (e) {
          // Fallback to StreamAudioSource-based playback.
          audioSource =
              YouTubeAudioSource(videoId: id, quality: quality, tag: mediaItem);
        }
      } else {
        String? kurl = await getJsQualityURL(mediaItem.extras?["url"]);
        if (kurl == null || kurl.isEmpty) {
          throw Exception('Failed to get stream URL');
        }

        log('Playing: $kurl', name: "AudioSourceManager");
        audioSource = AudioSource.uri(Uri.parse(kurl), tag: mediaItem);
      }

      return audioSource;
    } catch (e) {
      log('Error getting audio source for ${mediaItem.title}: $e',
          name: "AudioSourceManager");
      rethrow;
    }
  }

  // Cache-related getters removed
}
