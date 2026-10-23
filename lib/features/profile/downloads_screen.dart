import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/mixins/screenshot_protected_screen.dart';
import 'data/downloads_repository.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> with ScreenshotProtectedScreen {
  @override
  Widget build(BuildContext context) {
    final downloadsAsync = ref.watch(myDownloadsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Downloads', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: downloadsAsync.when(
        data: (downloads) {
          if (downloads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_download_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No downloads yet',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Files you save will appear here.',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final item = downloads[index];
              final dateStr = item['download_date'] as String?;
              final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
              final formattedDate = date != null 
                  ? '${date.day}/${date.month}/${date.year}' 
                  : 'Unknown Date';

              return Container(
                margin: const Offset(0, 0) == const Offset(0, 0) ? const EdgeInsets.only(bottom: 12) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.blueAccent),
                  ),
                  title: Text(
                    item['title'] ?? 'Document',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(item['subject'] ?? 'Unknown Subject', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 10, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('Downloaded: $formattedDate', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () async {
                      await ref.read(downloadsRepositoryProvider).removeDownload(item['url']);
                      ref.invalidate(myDownloadsProvider);
                    },
                  ),
                  onTap: () {
                    context.push('/file_viewer', extra: {
                      'id': item['id'] ?? '',
                      'year': item['year'] ?? '',
                      'subject': item['subject'] ?? '',
                      'title': item['title'] ?? item['file_name'] ?? 'Document',
                      'url': item['url'] ?? item['file_url'] ?? '',
                      'file_url': item['url'] ?? item['file_url'] ?? '',
                      'storage_path': item['storage_path'] ?? '',
                      'media_type': item['media_type'] ?? 'pdf',
                    });
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

