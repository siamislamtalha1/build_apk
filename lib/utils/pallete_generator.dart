import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:Bloomee/utils/load_Image.dart';

Future<PaletteGenerator> getPalleteFromImage(String url) async {
  ImageProvider<Object> placeHolder =
      const AssetImage("assets/icons/bloomee_new_logo_c.png");

  final raw = url.trim();
  final uri = Uri.tryParse(raw);
  final scheme = (uri?.scheme ?? '').toLowerCase();

  ImageProvider<Object> provider;
  final isHttp = raw.isNotEmpty &&
      (scheme == 'http' || scheme == 'https') &&
      (uri?.host.isNotEmpty ?? false);
  if (isHttp) {
    provider = CachedNetworkImageProvider(raw);
  } else {
    provider = safeImageProvider(raw, placeholderPath: "assets/icons/bloomee_new_logo_c.png");
  }

  try {
    return await PaletteGenerator.fromImageProvider(provider);
  } catch (_) {
    return await PaletteGenerator.fromImageProvider(placeHolder);
  }
}
