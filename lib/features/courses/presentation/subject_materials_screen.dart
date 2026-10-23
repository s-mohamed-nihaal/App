import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Absolute imports for maximum stability
import 'package:unani_academy/core/theme/app_theme.dart';
import 'package:unani_academy/core/widgets/premium_image.dart';
import 'package:unani_academy/features/courses/data/course_repository.dart';
import 'package:unani_academy/features/courses/data/material_model.dart';
import 'package:unani_academy/features/profile/data/downloads_repository.dart';

class SubjectMaterialsScreen extends ConsumerStatefulWidget {
  final String year;
  final String subject;
  final String? subjectId; // Added subjectId

  const SubjectMaterialsScreen({
    super.key,
    required this.year,
    required this.subject,
    this.subjectId,
  });

  @override
  ConsumerState<SubjectMaterialsScreen> createState() => _SubjectMaterialsScreenState();
}

class _SubjectMaterialsScreenState extends ConsumerState<SubjectMaterialsScreen> {
  List<MaterialModel> _materials = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(courseRepositoryProvider);
      final all = await repo.fetchAllMaterials();
      
      // Filter by specified year and subject (or subjectId)
      final filtered = all.where((m) {
        final yearMatch = m.year.toLowerCase().trim() == widget.year.toLowerCase().trim();
        
        // Priority 1: Match by subjectId if available
        if (widget.subjectId != null && m.subjectId != null) {
          return yearMatch && m.subjectId == widget.subjectId;
        }
        
        // Priority 2: Fallback to case-insensitive name matching
        return yearMatch && m.subject.toLowerCase().trim() == widget.subject.toLowerCase().trim();
      }).toList();

      if (mounted) {
        setState(() {
          _materials = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _error = 'Failed to load materials. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('${widget.subject} Materials', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchMaterials,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_materials.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _materials.length,
      itemBuilder: (context, index) => _buildMaterialCard(context, _materials[index]),
    );
  }

  Widget _buildMaterialCard(BuildContext context, MaterialModel material) {
    final isVideo = material.mediaType == 'video' || 
                    material.resolvedUrl.toLowerCase().contains('.mp4');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: PremiumImage(
          imageUrl: material.resolvedThumbnailUrl ?? '',
          width: 60,
          height: 60,
          borderRadius: 12,
          fallbackIcon: isVideo ? Icons.play_circle_fill_rounded : Icons.picture_as_pdf_rounded,
        ),
        title: Text(
          material.title ?? material.fileName.replaceAll('_', ' '),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                isVideo ? Icons.play_circle_outline_rounded : Icons.description_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                isVideo ? 'Video Lecture' : 'PDF Document',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.cloud_download_outlined, color: Colors.blueAccent, size: 20),
              onPressed: () async {
                await ref.read(downloadsRepositoryProvider).addDownload({
                  'title': material.title ?? material.fileName.replaceAll('_', ' '),
                  'subject': widget.subject,
                  'url': material.resolvedUrl,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved to My Downloads'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
        onTap: () => context.push('/file_viewer', extra: material),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No materials found.', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Materials added by admin will appear here.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMaterials,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
