import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_character.dart';

final customCharacterProvider =
    StateNotifierProvider<CustomCharacterNotifier, List<CustomCharacter>>(
        (ref) {
  return CustomCharacterNotifier();
});

class CustomCharacterNotifier extends StateNotifier<List<CustomCharacter>> {
  static const _prefsKey = 'custom_characters';

  CustomCharacterNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    final characters = raw
        .map((s) => CustomCharacter.fromJson(jsonDecode(s)))
        .where((c) => File(c.imagePath).existsSync())
        .toList();
    state = characters;
  }

  Future<void> addCharacter(CustomCharacter character) async {
    state = [...state, character];
    await _persist();
  }

  Future<void> removeCharacter(String id) async {
    final target = state.where((c) => c.id == id).toList();
    if (target.isNotEmpty && File(target.first.imagePath).existsSync()) {
      await File(target.first.imagePath).delete();
    }
    state = state.where((c) => c.id != id).toList();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      state.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }
}
