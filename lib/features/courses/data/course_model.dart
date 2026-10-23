class Course {
  final String id;
  final String title;
  final String? subject;
  final String? subjectId; // New field
  final double price;
  final String year;
  final String fileUrl;
  final DateTime createdAt;
  final Duration accessDuration;

  Course({
    required this.id,
    required this.title,
    this.subject,
    this.subjectId,
    required this.price,
    required this.year,
    required this.fileUrl,
    required this.createdAt,
    this.accessDuration = const Duration(days: 30),
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String?,
      subjectId: json['subject_id'] as String?,
      price: (json['price'] as num).toDouble(),
      year: json['year'] as String,
      fileUrl: (json['file_url'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      accessDuration: Duration(days: json['access_duration_days'] as int? ?? 30),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'subject_id': subjectId,
      'price': price,
      'year': year,
      'file_url': fileUrl,
    };
  }
}

