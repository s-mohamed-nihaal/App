import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'data/material_model.dart';
import '../../core/theme/app_theme.dart';
import '../profile/data/downloads_repository.dart';

// Mobile-only imports — guarded by kIsWeb checks at runtime
import 'pdf_viewer_mobile.dart' if (dart.library.html) 'pdf_viewer_web.dart';
import '../../core/mixins/screenshot_protected_screen.dart';

class FileViewerScreen extends ConsumerStatefulWidget {
  final MaterialModel material;
  const FileViewerScreen({super.key, required this.material});

  @override
  ConsumerState<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends ConsumerState<FileViewerScreen> with ScreenshotProtectedScreen {
  late bool _isVideo;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _videoLoading = true;
  bool _isError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isVideo = widget.material.mediaType == 'video' ||
        widget.material.resolvedUrl.toLowerCase().contains('.mp4') ||
        widget.material.resolvedUrl.toLowerCase().contains('.mkv');

    if (_isVideo) _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.material.resolvedUrl),
      );
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: const Center(
            child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (context, msg) => Center(
            child: Text(msg,
                style: const TextStyle(color: Colors.white))),
      );
      if (mounted) setState(() => _videoLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _videoLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _handleSaveToDownloads() async {
    try {
      await ref.read(downloadsRepositoryProvider).addDownload({
        'id': widget.material.id,
        'title': widget.material.title ??
            widget.material.fileName.replaceAll('_', ' '),
        'subject': widget.material.subject,
        'year': widget.material.year,
        'url': widget.material.resolvedUrl,
        'file_url': widget.material.resolvedUrl,
        'file_name': widget.material.fileName,
        'media_type': widget.material.mediaType ?? 'pdf',
        'storage_path': widget.material.storagePath,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Saved to My Downloads'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.material.title ??
        widget.material.fileName.replaceAll('_', ' ');

    return Scaffold(
      backgroundColor: _isVideo ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        backgroundColor: _isVideo ? Colors.black : null,
        foregroundColor: _isVideo ? Colors.white : null,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Save to Downloads',
            onPressed: _handleSaveToDownloads,
          ),
        ],
      ),
      body: _isError
          ? _buildErrorState()
          : _isVideo
              ? _buildVideoPlayer()
              : PlatformPdfViewer(url: widget.material.resolvedUrl),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (_chewieController != null &&
        _chewieController!
            .videoPlayerController.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }
    return const Center(
        child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Could not load this file',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Unknown error.',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleSaveToDownloads,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Save to My Downloads'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                final url = Uri.parse(widget.material.resolvedUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url,
                      mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open in Browser'),
            ),
          ],
        ),
      ),
    );
  }
}
