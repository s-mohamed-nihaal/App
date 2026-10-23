import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import 'course_model.dart';
import 'material_model.dart';

import '../../../core/services/persistence_service.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(ref.watch(supabaseProvider), ref.watch(persistenceServiceProvider));
});

final materialsBySubjectProvider = FutureProvider.family<List<MaterialModel>, Map<String, String>>((ref, params) async {
  final year = params['year']!;
  final subjectId = params['subject_id']!; // Use subject_id
  return ref.watch(courseRepositoryProvider).fetchMaterialsBySubject(year, subjectId);
});

final allMaterialsProvider = FutureProvider<List<MaterialModel>>((ref) async {
  return ref.watch(courseRepositoryProvider).fetchAllMaterials();
});

final coursesByYearProvider = FutureProvider.family<List<Course>, String>((ref, year) async {
  return ref.watch(courseRepositoryProvider).fetchCoursesByYear(year);
});

final recentCoursesProvider = FutureProvider<List<Course>>((ref) async {
  return ref.watch(courseRepositoryProvider).fetchRecentCourses();
});

final allCoursesProvider = FutureProvider<List<Course>>((ref) async {
  return ref.watch(courseRepositoryProvider).fetchAllCourses();
});

final purchaseHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(courseRepositoryProvider).fetchPurchases();
});

final unlockedSubjectsProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.fetchUnlockedSubjectNames();
});

/// A simpler provider to handle the refresh logic.
final purchaseStatusNotifierProvider = StateProvider<int>((ref) => 0);

class CourseRepository {
  final SupabaseClient _supabase;
  final PersistenceService _persistence;
  static const _bucket = 'study-materials';

  CourseRepository(this._supabase, this._persistence);

  // ─── Helper: Sanitize file name ────────────────────────────────────────────
  /// Aggressively sanitizes a filename for URL safety.
  /// 1. Lowercase everything.
  /// 2. Replace all whitespace (spaces, tabs, newlines) with underscores.
  /// 3. Remove all non-alphanumeric characters except underscores, hyphens, and dots.
  static String sanitizeFileName(String rawName) {
    String name = rawName.toLowerCase();
    
    // Replace all whitespace sequences with a single underscore
    name = name.replaceAll(RegExp(r'\s+'), '_');
    
    // Remove characters that aren't letters, numbers, underscores, hyphens, or dots
    name = name.replaceAll(RegExp(r'[^a-z0-9_\-\.]'), '_');
    
    // Ensure it ends with .pdf if it's supposed to be a PDF
    if (!name.endsWith('.pdf') && !name.contains('.')) {
      name = '$name.pdf';
    }
    
    return name;
  }

  // ─── Courses ────────────────────────────────────────────────────────────────

  Future<List<Course>> fetchCoursesByYear(String year) async {
    final response = await _supabase
        .from('courses')
        .select()
        .eq('year', year)
        .order('created_at', ascending: false);
    
    final allCourses = (response as List).map((json) => Course.fromJson(json)).toList();
    
    // Deduplicate by SUBJECT name (e.g., if "Anatomy" exists twice, only keep the first one found)
    final uniqueCoursesMap = <String, Course>{};
    for (final course in allCourses) {
      final key = course.subject ?? course.title;
      if (!uniqueCoursesMap.containsKey(key)) {
        uniqueCoursesMap[key] = course;
      }
    }
    return uniqueCoursesMap.values.toList();
  }

  Future<List<Course>> fetchRecentCourses({int limit = 6}) async {
    final response = await _supabase
        .from('courses')
        .select()
        .order('created_at', ascending: false);
    
    final allCourses = (response as List).map((json) => Course.fromJson(json)).toList();
    
    // Deduplicate by title/subject
    final uniqueCoursesMap = <String, Course>{};
    for (final course in allCourses) {
      final key = course.subject ?? course.title;
      if (!uniqueCoursesMap.containsKey(key)) {
        uniqueCoursesMap[key] = course;
      }
    }
    
    final list = uniqueCoursesMap.values.toList();
    return list.take(limit).toList();
  }

  Future<List<Course>> fetchAllCourses() async {
    final response = await _supabase
        .from('courses')
        .select()
        .order('created_at', ascending: false);
    
    final allCourses = (response as List).map((json) => Course.fromJson(json)).toList();
    
    // Deduplicate
    final uniqueCoursesMap = <String, Course>{};
    for (final course in allCourses) {
      final key = course.subject ?? course.title;
      if (!uniqueCoursesMap.containsKey(key)) {
        uniqueCoursesMap[key] = course;
      }
    }
    return uniqueCoursesMap.values.toList();
  }

  // ─── Materials ──────────────────────────────────────────────────────────────

  Future<List<MaterialModel>> fetchMaterialsBySubject(String year, String subjectId) async {
    try {
      debugPrint('[FETCH] Materials for year=$year, subjectId=$subjectId');
      final response = await _supabase
          .from('materials')
          .select()
          .eq('year', year)
          .eq('subject_id', subjectId) // Use subject_id
          .order('created_at', ascending: false);

      if ((response as List).isEmpty) return [];

      return response.map((json) => MaterialModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[FETCH ERROR] $e');
      rethrow;
    }
  }

  Future<List<MaterialModel>> fetchAllMaterials() async {
    try {
      final response = await _supabase
          .from('materials')
          .select()
          .order('created_at', ascending: false);

      if ((response as List).isEmpty) return [];

      return response.map((json) => MaterialModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[FETCH ALL ERROR] $e');
      rethrow;
    }
  }

  /// Uploads media content (PDF/Video) along with an optional thumbnail image.
  /// Organizes files into subfolders: uploads/pdfs, uploads/videos, uploads/images.
  Future<String> uploadMedia({
    required String year,
    required String subject,
    required String subjectId, // Added subjectId
    required String mediaType, // 'pdf' or 'video'
    required String mainFileName,
    required Uint8List mainFileBytes,
    String? thumbFileName,
    Uint8List? thumbBytes,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 1. Upload Main Content (PDF/Video)
      final cleanMainName = sanitizeFileName(mainFileName);
      final subFolder = mediaType == 'video' ? 'videos' : 'pdfs';
      final mainStoragePath = 'uploads/$subFolder/${timestamp}_$cleanMainName';
      
      await _supabase.storage.from(_bucket).uploadBinary(
            mainStoragePath,
            mainFileBytes,
            fileOptions: FileOptions(
              contentType: mediaType == 'video' ? 'video/mp4' : 'application/pdf',
              cacheControl: '3600',
              upsert: true,
            ),
          );
      final mainUrl = _supabase.storage.from(_bucket).getPublicUrl(mainStoragePath);

      // 2. Upload Optional Thumbnail
      String? thumbUrl;
      if (thumbFileName != null && thumbBytes != null) {
        final cleanThumbName = sanitizeFileName(thumbFileName);
        final thumbStoragePath = 'uploads/images/${timestamp}_$cleanThumbName';
        await _supabase.storage.from(_bucket).uploadBinary(
              thumbStoragePath,
              thumbBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        thumbUrl = _supabase.storage.from(_bucket).getPublicUrl(thumbStoragePath);
      }

      // 3. Save to Database
      await _supabase.from('materials').insert({
        'year': year,
        'subject': subject,
        'subject_id': subjectId, // Include subject_id
        'media_type': mediaType,
        'file_name': cleanMainName,
        'file_url': mainUrl,           // Always save the main URL here too
        'storage_path': mainStoragePath,
        'image_path': thumbUrl,
        'video_path': mediaType == 'video' ? mainUrl : null,  // For videos, also save here
        'title': cleanMainName.split('.').first.replaceAll('_', ' ').replaceAll(RegExp(r'^\d+_'), ''),
      });

      return cleanMainName;
    } catch (e) {
      debugPrint('[MEDIA UPLOAD ERROR] $e');
      rethrow;
    }
  }

  Future<void> deleteMaterial(String id, String fileUrl) async {
    await _supabase.from('materials').delete().eq('id', id);
    try {
      final uri = Uri.parse(fileUrl);
      final pathParts = uri.path.split('/');
      final bucketIndex = pathParts.indexOf(_bucket);
      if (bucketIndex != -1 && bucketIndex + 1 < pathParts.length) {
        final storagePath = pathParts.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(_bucket).remove([storagePath]);
      }
    } catch (e) {
      debugPrint('[DELETE STORAGE ERROR] $e');
    }
  }

  // ─── Courses (file upload) ──────────────────────────────────────────────────

  Future<void> uploadCourse({
    required String title,
    required String subject,
    required String subjectId, // Added subjectId
    required int price,
    required String year,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final cleanFileName = sanitizeFileName(fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Use consistent 'uploads/' prefix with timestamp and clean name
    final storagePath = 'uploads/${timestamp}_$cleanFileName';

    await _supabase.storage.from(_bucket).uploadBinary(storagePath, fileBytes);

    final fileUrl = _supabase.storage.from(_bucket).getPublicUrl(storagePath);

    await _supabase.from('courses').insert({
      'title': title,
      'subject': subject,
      'subject_id': subjectId, // Include subject_id
      'year': year,
      'price': price,
      'file_url': fileUrl,
    });
  }

  Future<void> deleteCourse(String id, String fileUrl) async {
    await _supabase.from('courses').delete().eq('id', id);
    try {
      final uri = Uri.parse(fileUrl);
      final pathParts = uri.path.split('/');
      final bucketIndex = pathParts.indexOf(_bucket);
      if (bucketIndex != -1 && bucketIndex + 1 < pathParts.length) {
        final storagePath = pathParts.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(_bucket).remove([storagePath]);
      }
    } catch (e) {
      debugPrint('[DELETE COURSE STORAGE ERROR] $e');
    }
  }

  // ─── Purchases ──────────────────────────────────────────────────────────────

  Future<bool> isPurchased(String subjectName) async {
    final unlocked = await fetchUnlockedSubjectNames();
    return unlocked.contains(subjectName);
  }

  Future<void> purchaseCourse({
    required String subjectName,
    required String courseId,
    required String paymentId,
    required int amount,
  }) async {
    // 1. Save locally FIRST for instant unlock
    await _persistence.unlockSubject(subjectName);
    
    // Note: Supabase insert is now handled directly by PaymentService
  }

  Future<void> purchaseBundle({
    required String yearMarker,
    required String courseId,
    required String paymentId,
    required int amount,
    required List<String> subjects,
  }) async {
    // 1. Local unlock
    await _persistence.unlockAllInYear(yearMarker);

    // Note: Supabase insert is now handled directly by PaymentService
  }

  Future<List<Map<String, dynamic>>> fetchPurchases() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await _supabase
          .from('purchases')
          .select('*')
          .eq('user_id', user.id)
          .order('purchased_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[FETCH PURCHASES ERROR] $e');
      return [];
    }
  }

  Future<Set<String>> fetchUnlockedSubjectNames() async {
    final unlocked = await _persistence.getUnlockedSubjects();

    final user = _supabase.auth.currentUser;
    if (user == null) return unlocked;

    try {
      final purchases = await fetchPurchases();
      for (final p in purchases) {
        final courseName = p['course_name'] as String? ?? '';
        final validUntilStr = p['valid_until'] as String?;
        final status = p['status'] as String? ?? 'active';

        // Check if purchase is expired
        if (status != 'active') continue;
        if (validUntilStr != null) {
          final expiry = DateTime.tryParse(validUntilStr);
          if (expiry != null && DateTime.now().isAfter(expiry)) {
            continue; // Skip expired content
          }
        }

        if (courseName.isEmpty) continue;

        if (courseName.toLowerCase().contains('combo') || courseName.toLowerCase().contains('package')) {
          if (courseName.toLowerCase().contains('first') || courseName.toLowerCase().contains('year 1')) {
            unlocked.add('ALL_First Year');
            unlocked.add('ALL_Year 1');
          } else if (courseName.toLowerCase().contains('second') || courseName.toLowerCase().contains('year 2')) {
            unlocked.add('ALL_Second Year');
            unlocked.add('ALL_Year 2');
          } else if (courseName.toLowerCase().contains('final') || courseName.toLowerCase().contains('year 3') || courseName.toLowerCase().contains('year 4')) {
            unlocked.add('ALL_Final Year');
          }
        } else {
          unlocked.add(courseName);
        }
      }
      return unlocked;
    } catch (e) {
      debugPrint('[FETCH UNLOCKED ERROR] $e');
      return unlocked;
    }
  }
}
