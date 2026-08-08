import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ar_character.dart';
import '../utils/logger.dart';

class ARCharacterService {
  static final ARCharacterService _instance = ARCharacterService._internal();

  factory ARCharacterService() {
    return _instance;
  }

  ARCharacterService._internal();

  final List<ARCharacter> _characters = [];
  bool _initialized = false;

  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load characters from JSON asset
      final jsonString = await rootBundle.loadString('assets/data/characters.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final charactersList = jsonData['characters'] as List;

      _characters.clear();
      for (final charJson in charactersList) {
        _characters.add(ARCharacter.fromJson(charJson));
      }

      _initialized = true;
    } catch (e) {
      AppLogger.error('Error loading AR characters', e);
      _initialized = false;
      rethrow;
    }
  }

  List<ARCharacter> getAllCharacters() {
    return List.unmodifiable(_characters);
  }

  List<ARCharacter> getFreeCharacters() {
    return _characters.where((c) => c.isFree).toList();
  }

  List<ARCharacter> getPaidCharacters() {
    return _characters.where((c) => !c.isFree).toList();
  }

  ARCharacter? getCharacterById(String characterId) {
    try {
      return _characters.firstWhere((c) => c.characterId == characterId);
    } catch (e) {
      return null;
    }
  }

  List<ARCharacter> getCharactersByCategory(CharacterCategory category) {
    return _characters.where((c) => c.category == category).toList();
  }

  List<ARCharacter> getCharactersByPack(CharacterPack pack) {
    return _characters.where((c) => c.packId == pack).toList();
  }

  Future<String?> getCharacterModel3DPath(String characterId) async {
    final character = getCharacterById(characterId);
    return character?.model3dUrl;
  }
}
