// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:http/http.dart' as http;

ImageProvider<Object> safeImageProvider(
  String? imageUrl, {
  String placeholderPath = "assets/icons/bloomee_new_logo_c.png",
}) {
  final placeholder = AssetImage(placeholderPath);
  final raw = (imageUrl ?? '').trim();
  if (raw.isEmpty) return placeholder;

  Uri? uri;
  try {
    uri = Uri.tryParse(raw);
  } catch (_) {
    uri = null;
  }

  final scheme = (uri?.scheme ?? '').toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    return NetworkImage(raw);
  }

  if (scheme == 'file' && uri != null) {
    try {
      final path = uri.toFilePath(windows: Platform.isWindows);
      final type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.file) {
        return FileImage(File(path));
      }
    } catch (_) {
      return placeholder;
    }
    return placeholder;
  }

  final isWindowsPath = RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(raw);
  if (isWindowsPath || raw.startsWith('/') || raw.startsWith('\\')) {
    try {
      final type = FileSystemEntity.typeSync(raw);
      if (type == FileSystemEntityType.file) {
        return FileImage(File(raw));
      }
    } catch (_) {
      return placeholder;
    }
    return placeholder;
  }

  return placeholder;
}

Image loadImage(coverImageUrl,
    {placeholderPath = "assets/icons/bloomee_new_logo_c.png"}) {
  return Image(
    image: safeImageProvider(
      coverImageUrl?.toString(),
      placeholderPath: placeholderPath,
    ),
    fit: BoxFit.cover,
  );
}

CachedNetworkImage loadImageCached(coverImageURL,
    {placeholderPath = "assets/icons/bloomee_new_logo_c.png",
    fit = BoxFit.cover}) {
  ImageProvider<Object> placeHolder = AssetImage(placeholderPath);
  return CachedNetworkImage(
    imageUrl: coverImageURL,
    memCacheWidth: 500,
    // memCacheHeight: 500,
    placeholder: (context, url) => Image(
      image: const AssetImage("assets/icons/lazy_loading.png"),
      fit: fit,
    ),
    errorWidget: (context, url, error) => Image(
      image: placeHolder,
      fit: fit,
    ),
    fadeInDuration: const Duration(milliseconds: 700),
    fit: fit,
  );
}

class LoadImageCached extends StatefulWidget {
  final String imageUrl;
  final String? fallbackUrl;
  final String placeholderUrl;
  final BoxFit fit;

  const LoadImageCached({
    Key? key,
    required this.imageUrl,
    this.placeholderUrl = "assets/icons/bloomee_new_logo_c.png",
    this.fit = BoxFit.cover,
    this.fallbackUrl,
  }) : super(key: key);

  @override
  State<LoadImageCached> createState() => _LoadImageCachedState();
}

class _LoadImageCachedState extends State<LoadImageCached> {
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      placeholder: (context, url) => Image(
        image: const AssetImage("assets/icons/lazy_loading.png"),
        fit: widget.fit,
      ),
      errorWidget: (context, url, error) => widget.fallbackUrl == null
          ? Image(
              image: AssetImage(widget.placeholderUrl),
              fit: widget.fit,
            )
          : CachedNetworkImage(
              // now using fallback url
              imageUrl: widget.fallbackUrl!,
              memCacheWidth: 500,
              placeholder: (context, url) => Image(
                image: const AssetImage("assets/icons/lazy_loading.png"),
                fit: widget.fit,
              ),
              errorWidget: (context, url, error) => Image(
                image: AssetImage(widget.placeholderUrl),
                fit: widget.fit,
              ),
              fadeInDuration: const Duration(milliseconds: 300),
              fit: widget.fit,
            ),
      fadeInDuration: const Duration(milliseconds: 300),
      fit: widget.fit,
    );
  }
}

Future<ImageProvider> getImageProvider(String imageUrl,
    {String placeholderUrl = "assets/icons/bloomee_new_logo_c.png"}) async {
  if (imageUrl != "") {
    final response = await http.head(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      CachedNetworkImageProvider cachedImageProvider =
          CachedNetworkImageProvider(imageUrl);
      return cachedImageProvider;
    } else {
      return AssetImage(placeholderUrl);
    }
  }
  return AssetImage(placeholderUrl);
}
