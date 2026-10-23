class MaterialModel {
  final String id;
  final String year;
  final String subject;
  final String? subjectId;  // New field
  final String fileName;    // Display name (sanitized)
  final String fileUrl;     // Public URL (legacy)
  final String storagePath; // Content path (PDF/Video)
  final String? imagePath;  // Optional thumbnail path
  final String? videoPath;  // Optional video path (for video mediaType)
  final String? mediaType;  // 'pdf' or 'video'
  final String? title;      // Custom title (e.g. "Chapter 1")
  final DateTime createdAt;

  MaterialModel({
    required this.id,
    required this.year,
    required this.subject,
    this.subjectId,
    required this.fileName,
    required this.fileUrl,
    required this.storagePath,
    this.imagePath,
    this.videoPath,
    this.mediaType,
    this.title,
    required this.createdAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id:          json['id'] as String,
      year:        json['year'] as String? ?? 'Year 1',
      subject:     json['subject'] as String? ?? 'General',
      subjectId:   json['subject_id'] as String?,
      fileName:    json['file_name'] as String? ?? '',
      fileUrl:     json['file_url'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      imagePath:   json['image_path'] as String?,
      videoPath:   json['video_path'] as String?,
      mediaType:   json['media_type'] as String? ?? 'pdf',
      title:       json['title'] as String?,
      createdAt:   json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':           id,
      'year':         year,
      'subject':      subject,
      'subject_id':   subjectId,
      'file_name':    fileName,
      'file_url':     fileUrl,
      'storage_path': storagePath,
      'image_path':   imagePath,
      'video_path':   videoPath,
      'media_type':   mediaType,
      'title':        title,
      'created_at':   createdAt.toIso8601String(),
    };
  }


  /// Returns the most reliable public URL for the primary content.
  String get resolvedUrl {
    if (mediaType == 'video') {
      if (videoPath != null && videoPath!.isNotEmpty) return videoPath!;
      if (fileUrl.isNotEmpty) return fileUrl;
    }
    if (fileUrl.isNotEmpty) return fileUrl;
    if (storagePath.isNotEmpty) return storagePath;
    return '';
  }

  /// Returns the thumbnail URL if available.
  String? get resolvedThumbnailUrl => imagePath;
}
