import 'dart:ui';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class AudioSettingsBottomSheet extends StatelessWidget {
  const AudioSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Default_Theme.themeColor.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
          ),
          padding:
              const EdgeInsets.only(top: 10, bottom: 30, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Audio Enhancements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Unageo',
                ),
              ),
              const SizedBox(height: 20),

              Center(
                  child: Column(
                children: [
                  Icon(MingCute.tool_line,
                      size: 50, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(height: 10),
                  Text(
                    "Enhancements Temporarily Disabled\nfor Stability Improvements",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14),
                  ),
                ],
              )),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
