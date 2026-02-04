import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

Future<PaletteGenerator> getPalleteFromImage(String url) async {
  ImageProvider<Object> placeHolder =
      const AssetImage("assets/icons/bloomee_new_logo_c.png");

  final raw = url.trim();
  final uri = Uri.tryParse(raw);
  final scheme = (uri?.scheme ?? '').toLowerCase();
  final isValid = raw.isNotEmpty &&
      (scheme == 'http' || scheme == 'https') &&
      (uri?.host.isNotEmpty ?? false);
  if (!isValid) {
    return await PaletteGenerator.fromImageProvider(placeHolder);
  }

  try {
    return (await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(raw)));
  } catch (e) {
    return await PaletteGenerator.fromImageProvider(placeHolder);
  }
}
