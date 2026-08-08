
enum CharacterCategory { animal, mythical, object }

enum CharacterPack { free, pack01, pack02 }

class ARCharacter {
  final String characterId;
  final String name;
  final String model3dUrl; // path to .usdz or .glb
  final String? thumbnailUrl;
  final CharacterCategory category;
  final CharacterPack packId;
  final Map<String, String> animations; // idle, move, celebrate

  ARCharacter({
    required this.characterId,
    required this.name,
    required this.model3dUrl,
    this.thumbnailUrl,
    required this.category,
    required this.packId,
    required this.animations,
  });

  factory ARCharacter.fromJson(Map<String, dynamic> json) {
    return ARCharacter(
      characterId: json['characterId'] ?? '',
      name: json['name'] ?? '',
      model3dUrl: json['model3dUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      category: _parseCategory(json['category']),
      packId: _parsePack(json['packId']),
      animations: (json['animations'] as Map?)?.cast<String, String>() ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'characterId': characterId,
      'name': name,
      'model3dUrl': model3dUrl,
      'thumbnailUrl': thumbnailUrl,
      'category': category.toString().split('.').last,
      'packId': packId.toString().split('.').last,
      'animations': animations,
    };
  }

  static CharacterCategory _parseCategory(String? cat) {
    if (cat == null) return CharacterCategory.animal;
    switch (cat) {
      case 'mythical':
        return CharacterCategory.mythical;
      case 'object':
        return CharacterCategory.object;
      default:
        return CharacterCategory.animal;
    }
  }

  static CharacterPack _parsePack(String? pack) {
    if (pack == null) return CharacterPack.free;
    switch (pack) {
      case 'pack_01':
        return CharacterPack.pack01;
      case 'pack_02':
        return CharacterPack.pack02;
      default:
        return CharacterPack.free;
    }
  }

  bool get isFree => packId == CharacterPack.free;
}
