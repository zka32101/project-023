class CustomCharacter {
  final String id;
  final String name;
  final String imagePath;

  CustomCharacter({
    required this.id,
    required this.name,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
      };

  factory CustomCharacter.fromJson(Map<String, dynamic> json) {
    return CustomCharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
    );
  }
}
