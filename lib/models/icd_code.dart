class IcdCode {
  final String code;
  final String description;
  final String? chapter;
  final String? chapterTitle;
  final String classification;

  IcdCode({
    required this.code,
    required this.description,
    this.chapter,
    this.chapterTitle,
    required this.classification,
  });

  factory IcdCode.fromJson(Map<String, dynamic> json, String classification) {
    return IcdCode(
      code: json['code'] as String,
      description: json['description'] as String,
      chapter: json['chapter'] as String?,
      chapterTitle: json['chapter_title'] as String?,
      classification: classification,
    );
  }
}
