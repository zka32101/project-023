import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/services/ar_character_service.dart';
import 'package:tsukuani/models/ar_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ARCharacterService', () {
    late ARCharacterService service;

    setUp(() {
      service = ARCharacterService();
    });

    test('should initialize successfully', () async {
      await service.initialize();
      expect(service.initialized, isTrue);
    });

    test('should return all characters after initialization', () async {
      await service.initialize();
      final allCharacters = service.getAllCharacters();
      expect(allCharacters, isNotEmpty);
      expect(allCharacters.length, greaterThanOrEqualTo(10));
    });

    test('should filter free characters correctly', () async {
      await service.initialize();
      final freeCharacters = service.getFreeCharacters();
      expect(freeCharacters, isNotEmpty);
      for (final char in freeCharacters) {
        expect(char.isFree, isTrue);
      }
    });

    test('should filter paid characters correctly', () async {
      await service.initialize();
      final paidCharacters = service.getPaidCharacters();
      for (final char in paidCharacters) {
        expect(char.isFree, isFalse);
      }
    });

    test('should get character by ID', () async {
      await service.initialize();
      final char = service.getCharacterById('char_001');
      expect(char, isNotNull);
      expect(char?.characterId, equals('char_001'));
    });

    test('should return null for non-existent character', () async {
      await service.initialize();
      final char = service.getCharacterById('nonexistent');
      expect(char, isNull);
    });

    test('should filter by category', () async {
      await service.initialize();
      final animals = service.getCharactersByCategory(CharacterCategory.animal);
      expect(animals, isNotEmpty);
      for (final char in animals) {
        expect(char.category, equals(CharacterCategory.animal));
      }
    });

    test('should filter by pack', () async {
      await service.initialize();
      final freePack = service.getCharactersByPack(CharacterPack.free);
      expect(freePack, isNotEmpty);
      for (final char in freePack) {
        expect(char.packId, equals(CharacterPack.free));
      }
    });
  });
}
