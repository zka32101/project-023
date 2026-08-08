import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import 'auth_provider.dart';

final projectListProvider = FutureProvider.family<List<Project>, String>((ref, userId) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getProjects();
});

final currentProjectProvider = StateNotifierProvider<CurrentProjectNotifier, String?>((ref) {
  return CurrentProjectNotifier();
});

final projectDetailProvider = FutureProvider.family<Project?, String>((ref, projectId) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final userId = firebaseService.userId;

  if (userId == null) return null;

  final projects = await ref.watch(projectListProvider(userId).future);
  try {
    return projects.firstWhere((p) => p.projectId == projectId);
  } catch (e) {
    return null;
  }
});

class CurrentProjectNotifier extends StateNotifier<String?> {
  CurrentProjectNotifier() : super(null);

  void setCurrentProject(String projectId) {
    state = projectId;
  }

  void clearCurrentProject() {
    state = null;
  }
}

final createProjectProvider = FutureProvider.family<String, String>((ref, title) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.createProject(title);
});
