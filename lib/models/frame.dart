import 'package:cloud_firestore/cloud_firestore.dart';

class ARCharacterData {
  final String characterId;
  final Map<String, double> position; // x, y, z in AR space
  final double scale;
  final double rotation; // in degrees

  ARCharacterData({
    required this.characterId,
    required this.position,
    required this.scale,
    required this.rotation,
  });

  factory ARCharacterData.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as Map<String, dynamic>? ?? {};
    return ARCharacterData(
      characterId: json['characterId'] ?? '',
      position: {
        'x': (pos['x'] ?? 0.0).toDouble(),
        'y': (pos['y'] ?? 0.0).toDouble(),
        'z': (pos['z'] ?? 0.0).toDouble(),
      },
      scale: (json['scale'] ?? 1.0).toDouble(),
      rotation: (json['rotation'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'characterId': characterId,
      'position': position,
      'scale': scale,
      'rotation': rotation,
    };
  }
}

class Frame {
  final String frameId;
  final DateTime capturedAt;
  final String imageUrl; // local path or Firebase Storage URL
  final List<ARCharacterData> characters;
  final int order; // timeline order

  Frame({
    required this.frameId,
    required this.capturedAt,
    required this.imageUrl,
    required this.characters,
    required this.order,
  });

  factory Frame.fromJson(Map<String, dynamic> json) {
    final charList = (json['characters'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return Frame(
      frameId: json['frameId'] ?? '',
      capturedAt: (json['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: json['imageUrl'] ?? '',
      characters: charList.map((c) => ARCharacterData.fromJson(c)).toList(),
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frameId': frameId,
      'capturedAt': capturedAt,
      'imageUrl': imageUrl,
      'characters': characters.map((c) => c.toJson()).toList(),
      'order': order,
    };
  }
}
