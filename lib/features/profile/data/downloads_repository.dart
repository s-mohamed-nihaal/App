import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final downloadsRepositoryProvider = Provider<DownloadsRepository>((ref) {
  return DownloadsRepository();
});

final myDownloadsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(downloadsRepositoryProvider).getDownloads();
});

class DownloadsRepository {
  static const _key = 'unani_downloads';

  Future<List<Map<String, dynamic>>> getDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> addDownload(Map<String, dynamic> material) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    
    // Create new entry
    final newEntry = {
      ...material,
      'download_date': DateTime.now().toIso8601String(),
    };

    // Avoid exact duplicates
    final existingIndex = data.indexWhere((e) {
      final decoded = jsonDecode(e);
      return decoded['url'] == material['url'];
    });

    if (existingIndex != -1) {
      data[existingIndex] = jsonEncode(newEntry);
    } else {
      data.add(jsonEncode(newEntry));
    }

    await prefs.setStringList(_key, data);
  }

  Future<void> removeDownload(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    
    data.removeWhere((e) {
      final decoded = jsonDecode(e);
      return decoded['url'] == url;
    });

    await prefs.setStringList(_key, data);
  }
}
