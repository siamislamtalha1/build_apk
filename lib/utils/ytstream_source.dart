import 'dart:async';
import 'dart:developer' as dev;
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<AudioOnlyStreamInfo> getStreamInfoBG(
    String videoId, RootIsolateToken? token, String quality) async {
  try {
    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }
    final ytExplode = YoutubeExplode();

    // Add timeout protection to prevent hanging
    final manifest = await ytExplode.videos.streams.getManifest(videoId,
        requireWatchPage: true,
        ytClients: [YoutubeApiClient.androidVr]).timeout(
      const Duration(seconds: 10),
      onTimeout: () =>
          throw TimeoutException('YouTube manifest fetch timed out'),
    );

    final supportedStreams = manifest.audioOnly.sortByBitrate();
    final audioStream = quality == 'high'
        ? supportedStreams.lastOrNull
        : supportedStreams.firstOrNull;

    if (audioStream == null) {
      throw Exception('No audio stream available for this video.');
    }

    ytExplode.close();
    return audioStream;
  } catch (e) {
    dev.log('Error in getStreamInfoBG: $e', name: 'YTStream');
    rethrow;
  }
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

  Future<AudioOnlyStreamInfo> getStreamInfo() async {
    try {
      final vidId = videoId;
      final qlty = quality;
      final token = RootIsolateToken.instance;

      // Try isolate execution with timeout
      try {
        final audioStream =
            await Isolate.run(() => getStreamInfoBG(vidId, token, qlty))
                .timeout(
          const Duration(seconds: 12),
          onTimeout: () =>
              throw TimeoutException('Isolate execution timed out'),
        );

        return audioStream;
      } catch (isolateError) {
        dev.log(
            'Isolate execution failed, falling back to direct execution: $isolateError',
            name: 'YTStream');

        // Fallback: Execute directly without isolate
        return await _getStreamInfoDirect(vidId, qlty);
      }
    } catch (e) {
      dev.log('Error getting stream info: $e', name: 'YTStream');
      rethrow;
    }
  }

  // Fallback method that doesn't use isolates
  Future<AudioOnlyStreamInfo> _getStreamInfoDirect(
      String videoId, String quality) async {
    try {
      final manifest = await ytExplode.videos.streams.getManifest(videoId,
          requireWatchPage: true,
          ytClients: [YoutubeApiClient.androidVr]).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw TimeoutException('YouTube manifest fetch timed out'),
      );

      final supportedStreams = manifest.audioOnly.sortByBitrate();
      final audioStream = quality == 'high'
          ? supportedStreams.lastOrNull
          : supportedStreams.firstOrNull;

      if (audioStream == null) {
        throw Exception('No audio stream available for this video.');
      }

      return audioStream;
    } catch (e) {
      dev.log('Direct stream fetch failed: $e', name: 'YTStream');
      rethrow;
    }
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    try {
      final audioStream = await getStreamInfo();

      start ??= 0;
      if (end != null && end > audioStream.size.totalBytes) {
        end = audioStream.size.totalBytes;
      }

      final stream = ytExplode.videos.streams.get(audioStream);

      return StreamAudioResponse(
        sourceLength: audioStream.size.totalBytes,
        contentLength:
            end != null ? end - start : audioStream.size.totalBytes - start,
        offset: start,
        stream: stream,
        contentType: audioStream.codec.mimeType,
      );
    } catch (e) {
      dev.log('Failed to load audio stream for $videoId: $e', name: 'YTStream');
      throw Exception('Failed to load YouTube audio for video $videoId: $e');
    }
  }
}
