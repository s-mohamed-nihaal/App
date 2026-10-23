import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';

class PlatformPdfViewer extends StatefulWidget {
  final String url;

  const PlatformPdfViewer({super.key, required this.url});

  @override
  State<PlatformPdfViewer> createState() => _PlatformPdfViewerState();
}

class _PlatformPdfViewerState extends State<PlatformPdfViewer> {
  String? _localPath;
  double _progress = 0;

  bool _loading = true;
  bool _isError = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _downloadAndLoad();
  }

  Future<void> _downloadAndLoad() async {
    try {
      setState(() {
        _loading = true;
        _isError = false;
        _progress = 0;
      });

      final dir = await getTemporaryDirectory();

      final filePath = '${dir.path}/pdf_${widget.url.hashCode}.pdf';

      final file = File(filePath);

      // DOWNLOAD PDF IF NOT EXISTS
      if (!await file.exists()) {
        await Dio().download(
          widget.url,
          filePath,
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() {
                _progress = received / total;
              });
            }
          },
        );
      }

      // SET LOCAL PATH
      if (mounted) {
        setState(() {
          _localPath = filePath;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _loading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ERROR UI
    if (_isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),

              const SizedBox(height: 12),

              Text(
                _errorMessage ?? 'Failed to load PDF',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _downloadAndLoad,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // LOADING UI
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),

            const SizedBox(height: 16),

            Text(
              _progress > 0
                  ? 'Loading... ${(_progress * 100).toInt()}%'
                  : 'Preparing...',
              style: const TextStyle(color: Colors.grey),
            ),

            if (_progress > 0) ...[
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(
                  value: _progress,
                  color: AppTheme.primaryColor,
                  backgroundColor: Colors.grey[300],
                ),
              ),
            ],
          ],
        ),
      );
    }

    // SAFETY CHECK
    if (_localPath == null) {
      return const Center(child: Text('PDF path is null'));
    }

    // PDF VIEWER
    return Container(
      color: const Color(0xFFE5E5E5),
      child: PDFView(
        filePath: _localPath!,

        // SCROLL SETTINGS
        enableSwipe: true,
        swipeHorizontal: false,
        pageFling: false,
        pageSnap: false,

        // SPACING
        autoSpacing: false,

        // WEB-LIKE LOOK
        fitPolicy: FitPolicy.WIDTH,

        // OPTIONAL
        nightMode: false,

        onError: (error) {
          if (mounted) {
            setState(() {
              _isError = true;
              _errorMessage = error.toString();
            });
          }
        },

        onPageError: (page, error) {
          debugPrint('Page error: $page => $error');
        },
      ),
    );
  }
}
