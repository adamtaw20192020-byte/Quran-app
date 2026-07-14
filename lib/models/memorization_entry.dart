class MemorizationEntry {
  // مستويات التقييم المتاحة، مرتبة من الأدنى إلى الأعلى
  static const List<String> ratingLevels = [
    'جيد',
    'جيد جداً',
    'ممتاز',
    'متميز',
  ];

  final String id;
  final String studentName;
  final DateTime date;
  final String newMemorization; // الحفظ الجديد
  final String review; // المراجعة
  final String rating; // التقييم: جيد / جيد جداً / ممتاز / متميز
  final String notes;

  MemorizationEntry({
    required this.id,
    required this.studentName,
    required this.date,
    required this.newMemorization,
    required this.review,
    required this.rating,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentName': studentName,
        'date': date.toIso8601String(),
        'newMemorization': newMemorization,
        'review': review,
        'rating': rating,
        'notes': notes,
      };

  factory MemorizationEntry.fromJson(Map<String, dynamic> json) {
    return MemorizationEntry(
      id: json['id'] as String,
      studentName: json['studentName'] as String,
      date: DateTime.parse(json['date'] as String),
      newMemorization: json['newMemorization'] as String,
      review: json['review'] as String,
      rating: json['rating'] as String,
      notes: (json['notes'] ?? '') as String,
    );
  }
}
