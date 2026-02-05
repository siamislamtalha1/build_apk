import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';

class SnackbarService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showMessage(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 2),
    bool loading = false,
  }) {
    // If there's no ScaffoldMessenger available (e.g., in background service)
    // avoid throwing. Log and return early so background code doesn't crash.
    if (messengerKey.currentState == null) {
      // Can't show snackbar right now; log and return.
      // UI layer can observe error streams and surface messages when ready.
      // ignore: avoid_print
      print(
          'SnackbarService: messengerKey.currentState is null, skipping snackbar: $message');
      return;
    }

    messengerKey.currentState!.removeCurrentSnackBar();

    final context = messengerKey.currentContext;
    final scheme = context != null ? Theme.of(context).colorScheme : null;
    final brightness = context != null ? Theme.of(context).brightness : null;
    final bgColor = scheme == null
        ? const Color.fromARGB(255, 16, 15, 15)
        : (brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : scheme.surface);
    final fgColor = scheme == null ? Default_Theme.primaryColor1 : scheme.onSurface;

    messengerKey.currentState!.showSnackBar(
      SnackBar(
        content: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(message,
                      style: TextStyle(
                          color: fgColor, fontSize: 16)),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            fgColor),
                      ),
                    ),
                  ),
                ],
              )
            : Text(message,
                style: TextStyle(
                    color: fgColor, fontSize: 16)),
        duration: loading ? const Duration(minutes: 1) : duration,
        showCloseIcon: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        closeIconColor: fgColor,
        elevation: 0,
        action: action,
        backgroundColor: bgColor,
      ),
    );
  }
}
