import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

mixin ScreenshotProtectedScreen<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _enableProtection();
  }

  @override
  void dispose() {
    _disableProtection();
    super.dispose();
  }

  Future<void> _enableProtection() async {
    try {
      // Blocks both screenshots and screen recording on Android & iOS
      await ScreenProtector.preventScreenshotOn();

      // On iOS, this specifically makes the screen go black during recording
      if (Platform.isIOS) {
        await ScreenProtector.preventScreenshotOn();
      }

      // Listener for screenshot attempts to show a feedback message
      ScreenProtector.addListener(
        () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.security_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text("Screenshot not allowed"),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        (p0) {
          // Screen recording listener (optional)
        },
      );
    } catch (e) {
      debugPrint('Error enabling screenshot protection: $e');
    }
  }

  Future<void> _disableProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      ScreenProtector.removeListener();
    } catch (e) {
      debugPrint('Error disabling screenshot protection: $e');
    }
  }
}
