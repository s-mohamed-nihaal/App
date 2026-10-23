// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

class PlatformPdfViewer extends StatefulWidget {
  final String url;
  const PlatformPdfViewer({super.key, required this.url});

  @override
  State<PlatformPdfViewer> createState() => _PlatformPdfViewerState();
}

class _PlatformPdfViewerState extends State<PlatformPdfViewer> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'pdf-iframe-${widget.url.hashCode}';

    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
