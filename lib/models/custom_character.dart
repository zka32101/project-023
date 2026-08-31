class CustomCharacter {
  final String id;
  final String name;
  final String imagePath;
  final String sourceType; // 'drawn' | 'photo'
  final String removalMethod; // 'none' | 'white' | 'manual' | 'ml'
  final bool hasTransparency;
  final DateTime createdAt;
  final int? originalFileSize;

  CustomCharacter({
    required this.id,
    required this.name,
    required this.imagePath,
    this.sourceType = 'drawn',
    this.removalMethod = 'none',
    this.hasTransparency = false,
    DateTime? createdAt,
    this.originalFileSize,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'sourceType': sourceType,
        'removalMethod': removalMethod,
        'hasTransparency': hasTransparency,
        'createdAt': createdAt.toIso8601String(),
        'originalFileSize': originalFileSize,
      };

  factory CustomCharacter.fromJson(Map<String, dynamic> json) {
    return CustomCharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
      sourceType: json['sourceType'] as String? ?? 'drawn',
      removalMethod: json['removalMethod'] as String? ?? 'none',
      hasTransparency: json['hasTransparency'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      originalFileSize: json['originalFileSize'] as int?,
    );
  }

  // コピーメソッド（更新用）
  CustomCharacter copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? sourceType,
    String? removalMethod,
    bool? hasTransparency,
    DateTime? createdAt,
    int? originalFileSize,
  }) {
    return CustomCharacter(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      sourceType: sourceType ?? this.sourceType,
      removalMethod: removalMethod ?? this.removalMethod,
      hasTransparency: hasTransparency ?? this.hasTransparency,
      createdAt: createdAt ?? this.createdAt,
      originalFileSize: originalFileSize ?? this.originalFileSize,
    );
  }
}
