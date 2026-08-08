import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ar_character.dart';
import '../services/ar_character_service.dart';

final arCharacterServiceProvider = Provider<ARCharacterService>((ref) {
  return ARCharacterService();
});

final arCharactersProvider = FutureProvider<List<ARCharacter>>((ref) async {
  final service = ref.watch(arCharacterServiceProvider);
  if (!service.initialized) {
    await service.initialize();
  }
  return service.getAllCharacters();
});

final freeCharactersProvider = FutureProvider<List<ARCharacter>>((ref) async {
  final service = ref.watch(arCharacterServiceProvider);
  if (!service.initialized) {
    await service.initialize();
  }
  return service.getFreeCharacters();
});

final selectedCharacterProvider = StateProvider<ARCharacter?>((ref) => null);
