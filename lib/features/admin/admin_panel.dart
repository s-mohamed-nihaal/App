import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:unani_academy/core/theme/app_theme.dart';
import 'package:unani_academy/core/constants/app_data.dart';
import 'package:unani_academy/features/courses/data/course_repository.dart';
import 'package:unani_academy/features/courses/data/material_model.dart';

class AdminPanel extends ConsumerStatefulWidget {
  const AdminPanel({super.key});

  @override
  ConsumerState<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends ConsumerState<AdminPanel> {
  String? _selectedYear;
  Subject? _selectedSubject;
  String _mediaType = 'pdf'; // 'pdf' or 'video'

  /// Content file (PDF or Video)
  String? _cleanFileName;
  Uint8List? _fileBytes;

  /// Optional Thumbnail
  String? _thumbFileName;
  Uint8List? _thumbBytes;

  bool _isUploading = false;

  // ── File Picker ─────────────────────────────────────────────────────────────

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _mediaType == 'video' ? ['mp4', 'mkv', 'mov'] : ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final raw = result.files.single.name;
      final clean = CourseRepository.sanitizeFileName(raw);

      setState(() {
        _fileBytes = result.files.single.bytes;
        _cleanFileName = clean;
      });
    }
  }

  void _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _thumbBytes = result.files.single.bytes;
        _thumbFileName = result.files.single.name;
      });
    }
  }

  // ── Publish ──────────────────────────────────────────────────────────────────

  void _handlePublish() async {
    if (_selectedYear == null ||
        _selectedSubject == null ||
        _fileBytes == null ||
        _cleanFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select year, subject and attach a file')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final savedName = await ref.read(courseRepositoryProvider).uploadMedia(
            year: _selectedYear!,
            subject: _selectedSubject!.name,
            subjectId: _selectedSubject!.id, // Pass subjectId
            mediaType: _mediaType,
            mainFileName: _cleanFileName!,
            mainFileBytes: _fileBytes!,
            thumbFileName: _thumbFileName,
            thumbBytes: _thumbBytes,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Published: $savedName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        ref.invalidate(allMaterialsProvider);

        setState(() {
          _cleanFileName = null;
          _fileBytes = null;
          _thumbFileName = null;
          _thumbBytes = null;
          _selectedSubject = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  void _handleDeleteMaterial(String id, String fileUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material?'),
        content: const Text('This will permanently remove the file from both the database and storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(courseRepositoryProvider).deleteMaterial(id, fileUrl);
        ref.invalidate(allMaterialsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUploadSection(),
            const Divider(height: 48, thickness: 1, endIndent: 24, indent: 24),
            _buildManagementSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload New Material',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),

          _buildStepCard(
            title: '1. Classification & Type',
            icon: Icons.category_rounded,
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(labelText: 'Academic Year'),
                  items: AppData.years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (val) => setState(() {
                    _selectedYear = val;
                    _selectedSubject = null;
                  }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Subject>(
                  initialValue: _selectedSubject,
                  decoration: const InputDecoration(labelText: 'Select Subject'),
                  items: (_selectedYear == null)
                      ? []
                      : AppData.getSubjectsByYear(_selectedYear!)
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                          .toList(),
                  onChanged: (val) => setState(() => _selectedSubject = val),
                  hint: const Text('Choose a subject first'),
                ),
                const SizedBox(height: 20),
                const Text('Content Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTypeToggle('pdf', 'PDF Document', Icons.picture_as_pdf_rounded),
                    const SizedBox(width: 12),
                    _buildTypeToggle('video', 'Video Lecture', Icons.play_circle_fill_rounded),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildStepCard(
            title: '2. Attach Files',
            icon: Icons.attachment_rounded,
            content: Column(
              children: [
                _buildFilePicker(
                  title: _mediaType == 'video' ? 'Select Video (MP4)' : 'Select PDF',
                  subtitle: _cleanFileName ?? 'No file chosen',
                  isPicked: _fileBytes != null,
                  onTap: _pickFile,
                  icon: _mediaType == 'video' ? Icons.movie_rounded : Icons.picture_as_pdf_rounded,
                ),
                const SizedBox(height: 16),
                _buildFilePicker(
                  title: 'Select Thumbnail (Optional Image)',
                  subtitle: _thumbFileName ?? 'Default icon will be used',
                  isPicked: _thumbBytes != null,
                  onTap: _pickThumbnail,
                  icon: Icons.image_rounded,
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_isUploading || _fileBytes == null) ? null : _handlePublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: _isUploading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Publish Study Material', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    final allMaterialsAsync = ref.watch(allMaterialsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Materials',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              IconButton(
                onPressed: () => ref.invalidate(allMaterialsProvider),
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          allMaterialsAsync.when(
            data: (materials) {
              if (materials.isEmpty) return _buildEmptyState();
              return _buildMaterialsList(materials);
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())),
            error: (e, _) => _buildErrorState(e),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(children: [Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), const Text('No materials uploaded yet.', style: TextStyle(color: Colors.grey))]),
      ),
    );
  }

  Widget _buildMaterialsList(List<MaterialModel> materials) {
    Map<String, Map<String, List<MaterialModel>>> grouped = {};
    for (final m in materials) {
      grouped.putIfAbsent(m.year, () => {});
      grouped[m.year]!.putIfAbsent(m.subject, () => []);
      grouped[m.year]![m.subject]!.add(m);
    }
    return Column(
      children: grouped.entries.map((yearEntry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(yearEntry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            children: yearEntry.value.entries.map((subjectEntry) {
              return ExpansionTile(
                leading: const Icon(Icons.folder_rounded, size: 20, color: Colors.amber),
                title: Text(subjectEntry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                children: subjectEntry.value.map((m) {
                  final isVideo = m.mediaType == 'video';
                  return ListTile(
                    dense: true,
                    leading: Icon(isVideo ? Icons.play_circle_fill_rounded : Icons.picture_as_pdf_rounded, color: isVideo ? Colors.red : Colors.blue, size: 18),
                    title: Text(m.title ?? m.fileName, style: const TextStyle(fontSize: 13)),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18), onPressed: () => _handleDeleteMaterial(m.id, m.resolvedUrl)),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(Object e) {
    return Center(
      child: Column(children: [const Icon(Icons.error_outline, color: Colors.red, size: 48), const SizedBox(height: 12), Text('Error: $e', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton(onPressed: () => ref.invalidate(allMaterialsProvider), child: const Text('Retry'))]),
    );
  }

  Widget _buildTypeToggle(String type, String label, IconData icon) {
    final isSelected = _mediaType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mediaType = type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey), const SizedBox(width: 8), Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))]),
        ),
      ),
    );
  }

  Widget _buildFilePicker({required String title, required String subtitle, required bool isPicked, required VoidCallback onTap, required IconData icon, Color? color}) {
    final colorVal = color ?? AppTheme.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colorVal.withValues(alpha: 0.03), border: Border.all(color: colorVal.withValues(alpha: 0.15)), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colorVal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(isPicked ? Icons.check_circle_rounded : icon, color: isPicked ? Colors.green : colorVal, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(color: isPicked ? Colors.grey[800] : Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)])),
            if (!isPicked) Icon(Icons.add_circle_outline_rounded, size: 18, color: colorVal.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({required String title, required IconData icon, required Widget content}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 20, color: AppTheme.primaryColor), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))]), const SizedBox(height: 20), content]),
      ),
    );
  }
}
