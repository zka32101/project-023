import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import 'auth_provider.dart';

final collectionProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final userId = firebaseService.userId;

  if (userId == null) return [];

  final projects = await firebaseService.getProjects();
  return projects.where((p) => p.status == ProjectStatus.exported).toList();
});

final collectionCountProvider = FutureProvider<int>((ref) async {
  final projects = await ref.watch(collectionProjectsProvider.future);
  return projects.length;
});

final unlockedCharactersProvider =
    StateNotifierProvider<UnlockedCharactersNotifier, Set<String>>((ref) {
  return UnlockedCharactersNotifier();
});

class UnlockedCharactersNotifier extends StateNotifier<Set<String>> {
  UnlockedCharactersNotifier() : super({});

  void addUnlockedCharacter(String characterId) {
    state = {...state, characterId};
  }

  void initializeFromProjectCount(int projectCount) {
    final unlocked = <String>{};
    if (projectCount >= 5) unlocked.add('char_005');
    if (projectCount >= 10) unlocked.add('char_010');
    if (projectCount >= 20) unlocked.add('char_020');
    state = unlocked;
  }
}

final nextUnlockedCharacterProvider = Provider<String?>((ref) {
  final count = ref.watch(collectionCountProvider);

  return count.when(
    data: (projectCount) {
      if (projectCount < 5) return 'char_005';
      if (projectCount < 10) return 'char_010';
      if (projectCount < 20) return 'char_020';
      return null;
    },
    error: (_, __) => null,
    loading: () => null,
  );
});

final projectsUntilNextUnlockProvider = Provider<int>((ref) {
  final count = ref.watch(collectionCountProvider);

  return count.when(
    data: (projectCount) {
      if (projectCount < 5) return 5 - projectCount;
      if (projectCount < 10) return 10 - projectCount;
      if (projectCount < 20) return 20 - projectCount;
      return 0;
    },
    error: (_, __) => 0,
    loading: () => 0,
  );
});
