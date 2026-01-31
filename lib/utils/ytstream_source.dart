import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:isolate';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<AudioOnlyStreamInfo> getStreamInfoBG(
    String videoId, RootIsolateToken? token, String quality) async {
  if (token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }
  final ytExplode = YoutubeExplode();
  final manifest = await ytExplode.videos.streams.getManifest(videoId,
      requireWatchPage: true, ytClients: [YoutubeApiClient.androidVr]);
  final supportedStreams = manifest.audioOnly.sortByBitrate();
  final audioStream = quality == 'high'
      ? supportedStreams.lastOrNull
      : supportedStreams.firstOrNull;
  if (audioStream == null) {
    throw Exception('No audio stream available for this video.');
  }
  return audioStream;
}

class YouTubeAudioSource extends StreamAudioSource {
  final String videoId;
  final String quality; // 'high' or 'low'
  final YoutubeExplode ytExplode;

  YouTubeAudioSource({
    required this.videoId,
    required this.quality,
    super.tag,
  }) : ytExplode = YoutubeExplode();

  String get _streamInfoCacheKey => 'streaminfo:$videoId';

  Future<List<AudioOnlyStreamInfo>> _fetchLowHighStreams() async {
    final manifest = await ytExplode.videos.streams.getManifest(
      videoId,
      requireWatchPage: true,
      ytClients: [YoutubeApiClient.androidVr],
    );
    final supportedStreams = manifest.audioOnly.sortByBitrate();
    final low = supportedStreams.firstOrNull;
    final high = supportedStreams.lastOrNull;
    if (low == null || high == null) {
      throw Exception('No audio stream available for this video.');
    }
    return [low, high];
  }

  Future<void> _cacheIfPossible({
    required AudioOnlyStreamInfo low,
    required AudioOnlyStreamInfo high,
  }) async {
    try {
      await cacheYtStreams(id: _streamInfoCacheKey, hURL: high, lURL: low);
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<AudioOnlyStreamInfo> getStreamInfo() async {
    // Use a dedicated key to avoid clobbering/being clobbered by the URL cache
    // used elsewhere in the app.
    final cachedStreams = await getStreamFromCache(_streamInfoCacheKey);
    if (cachedStreams != null) {
      return quality == 'high' ? cachedStreams[1] : cachedStreams[0];
    }

    // Prefer isolate for heavy work, but fall back to non-isolate path if isolate
    // initialization fails (observed to crash on some desktop/mobile builds).
    try {
      final vidId = videoId;
      final qlty = quality;
      final token = RootIsolateToken.instance;
      final audioStream =
          await Isolate.run(() => getStreamInfoBG(vidId, token, qlty));
      return audioStream;
    } catch (e) {
      // Fallback: fetch manifest on main isolate and cache both low/high.
      final streams = await _fetchLowHighStreams();
      await _cacheIfPossible(low: streams[0], high: streams[1]);
      return quality == 'high' ? streams[1] : streams[0];
    }
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    try {
      final audioStream = await getStreamInfo();

      // youtube_explode_dart (path dependency) does not support ranged stream
      // fetching via start/end in streams.get(). We still keep the StreamAudioSource
      // implementation for fallback use.
      final stream = ytExplode.videos.streams.get(audioStream);

      return StreamAudioResponse(
        sourceLength: audioStream.size.totalBytes,
        contentLength: audioStream.size.totalBytes,
        offset: 0,
        stream: stream,
        contentType: audioStream.codec.mimeType,
      );
    } catch (e) {
      throw Exception('Failed to load audio: $e');
    }
  }
}

Future<void> cacheYtStreams({
  required String id,
  required AudioOnlyStreamInfo hURL,
  required AudioOnlyStreamInfo lURL,
}) async {
  final match = RegExp('expire=(.*?)&').firstMatch(lURL.url.toString());
  final expireAt = match?.group(1) ??
      (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600 * 5.5).toString();

  try {
    BloomeeDBService.putYtLinkCache(
      id,
      jsonEncode(lURL.toJson()),
      jsonEncode(hURL.toJson()),
      int.parse(expireAt),
    );
    dev.log("Cached: $id, ExpireAt: $expireAt", name: "CacheYtStreams");
  } catch (e) {
    dev.log(e.toString(), name: "CacheYtStreams");
  }
}

Future<List<AudioOnlyStreamInfo>?> getStreamFromCache(String id) async {
  final cache = await BloomeeDBService.getYtLinkCache(id);
  if (cache != null) {
    final expireAt = cache.expireAt;
    if (expireAt > DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      // dev.log("Cache found: $id", name: "CacheYtStreams");
      if (cache.lowQURL == null) return null;

      // The ytLinkCacheDB is also used elsewhere to store plain URL strings.
      // If the stored value is not valid JSON for AudioOnlyStreamInfo, ignore it.
      try {
        return [
          AudioOnlyStreamInfo.fromJson(jsonDecode(cache.lowQURL!)),
          AudioOnlyStreamInfo.fromJson(jsonDecode(cache.highQURL)),
        ];
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}
