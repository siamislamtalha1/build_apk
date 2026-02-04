// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
  if ((scheme == 'http' || scheme == 'https') && (uri?.host.isNotEmpty ?? false)) {
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

Widget loadImageCached(coverImageURL,
    {placeholderPath = "assets/icons/bloomee_new_logo_c.png",
    fit = BoxFit.cover}) {
  final raw = (coverImageURL?.toString() ?? '').trim();
  if (raw.isEmpty) {
    return Image(image: AssetImage(placeholderPath), fit: fit);
  }
  final uri = Uri.tryParse(raw);
  final scheme = (uri?.scheme ?? '').toLowerCase();
  final isValid = (scheme == 'http' || scheme == 'https') && (uri?.host.isNotEmpty ?? false);
  if (!isValid) {
    return Image(image: AssetImage(placeholderPath), fit: fit);
  }

  ImageProvider<Object> placeHolder = AssetImage(placeholderPath);
  return CachedNetworkImage(
    imageUrl: raw,
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
  bool _isValidUrl(String url) {
    if (url.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      final scheme = uri.scheme.toLowerCase();
      // Must have http/https scheme and a valid host
      return (scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validate primary URL
    if (!_isValidUrl(widget.imageUrl)) {
      // Try fallback URL if available
      if (widget.fallbackUrl != null && _isValidUrl(widget.fallbackUrl!)) {
        return CachedNetworkImage(
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
        );
      }
      // No valid URL, return placeholder
      return Image(
        image: AssetImage(widget.placeholderUrl),
        fit: widget.fit,
      );
    }

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
          : _isValidUrl(widget.fallbackUrl!)
              ? CachedNetworkImage(
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
                )
              : Image(
                  image: AssetImage(widget.placeholderUrl),
                  fit: widget.fit,
                ),
      fadeInDuration: const Duration(milliseconds: 300),
      fit: widget.fit,
    );
  }
}

Future<ImageProvider> getImageProvider(String imageUrl,
    {String placeholderUrl = "assets/icons/bloomee_new_logo_c.png"}) async {
  final raw = imageUrl.trim();
  if (raw.isEmpty) return AssetImage(placeholderUrl);
  final uri = Uri.tryParse(raw);
  final scheme = (uri?.scheme ?? '').toLowerCase();
  final isValid = (scheme == 'http' || scheme == 'https') && (uri?.host.isNotEmpty ?? false);
  if (!isValid) return AssetImage(placeholderUrl);

  try {
    final response = await http.head(uri!);
    if (response.statusCode == 200) {
      CachedNetworkImageProvider cachedImageProvider =
          CachedNetworkImageProvider(raw);
      return cachedImageProvider;
    }
    return AssetImage(placeholderUrl);
  } catch (_) {
    return AssetImage(placeholderUrl);
  }
}
