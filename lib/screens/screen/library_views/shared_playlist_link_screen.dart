import 'package:Bloomee/screens/screen/library_views/cloud_playlist_import.dart';
import 'package:flutter/material.dart';

class SharedPlaylistLinkScreen extends StatefulWidget {
  final String shareId;
  const SharedPlaylistLinkScreen({super.key, required this.shareId});

  @override
  State<SharedPlaylistLinkScreen> createState() => _SharedPlaylistLinkScreenState();
}

class _SharedPlaylistLinkScreenState extends State<SharedPlaylistLinkScreen> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showCloudPlaylistImportDialogForShareId(
        context,
        shareId: widget.shareId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SizedBox(
          height: 48,
          width: 48,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
