import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return AuthNotifier(firebaseService);
});

class AuthState {
  final String? userId;
  final bool isLoading;
  final String? error;

  AuthState({
    this.userId,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    String? userId,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseService? _firebaseService;

  AuthNotifier(FirebaseService firebaseService)
      : _firebaseService = firebaseService,
        super(AuthState());

  AuthNotifier.withState(AuthState initialState)
      : _firebaseService = null,
        super(initialState);

  Future<void> anonymousSignIn() async {
    if (_firebaseService == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = await _firebaseService.anonymousSignIn();
      state = state.copyWith(userId: userId, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  String? get userId => state.userId;
}
