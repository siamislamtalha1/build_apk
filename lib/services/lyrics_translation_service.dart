import 'dart:convert';

import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:http/http.dart' as http;

class LyricsTranslationResult {
  final String translatedPlain;
  final List<String>? translatedSyncedLines;

  const LyricsTranslationResult({
    required this.translatedPlain,
    this.translatedSyncedLines,
  });

  Map<String, dynamic> toMap() {
    return {
      'translatedPlain': translatedPlain,
      'translatedSyncedLines': translatedSyncedLines,
    };
  }

  factory LyricsTranslationResult.fromMap(Map<String, dynamic> map) {
    return LyricsTranslationResult(
      translatedPlain: map['translatedPlain'] ?? '',
      translatedSyncedLines: (map['translatedSyncedLines'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}

class LyricsTranslationService {
  static const String _cacheKeyPrefix = 'lyricsTranslationCache';

  static Future<LyricsTranslationResult?> getCached({
    required String mediaId,
    required String targetLang,
  }) async {
    final key = '$_cacheKeyPrefix:$mediaId:$targetLang';
    final raw = await BloomeeDBService.getSettingStr(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return LyricsTranslationResult.fromMap(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> putCached({
    required String mediaId,
    required String targetLang,
    required LyricsTranslationResult result,
  }) async {
    final key = '$_cacheKeyPrefix:$mediaId:$targetLang';
    await BloomeeDBService.putSettingStr(key, jsonEncode(result.toMap()));
  }

  static Future<LyricsTranslationResult> translate({
    required String plainLyrics,
    required List<String>? syncedLines,
    required String targetLang,
  }) async {
    final translatedPlain = await _translateText(plainLyrics, targetLang);

    List<String>? translatedLines;
    if (syncedLines != null && syncedLines.isNotEmpty) {
      final joined = syncedLines.join('\n');
      final translatedJoined = await _translateText(joined, targetLang);
      final split = translatedJoined.split('\n');
      if (split.isNotEmpty) {
        translatedLines = split;
      }
    }

    return LyricsTranslationResult(
      translatedPlain: translatedPlain,
      translatedSyncedLines: translatedLines,
    );
  }

  static Future<String> _translateText(String text, String targetLang) async {
    if (text.trim().isEmpty) return text;

    final uri = Uri.parse('https://libretranslate.de/translate');

    final resp = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'q': text,
        'source': 'auto',
        'target': targetLang,
        'format': 'text',
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      return text;
    }

    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final translated = json['translatedText'];
      if (translated is String && translated.isNotEmpty) return translated;
      return text;
    } catch (_) {
      return text;
    }
  }
}
