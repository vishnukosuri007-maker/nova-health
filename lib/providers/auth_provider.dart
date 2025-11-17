import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

// Auth service provider
final authServiceProvider = Provider((ref) => AuthService());

// Current user provider
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  return CurrentUserNotifier(ref);
});

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  CurrentUserNotifier(this.ref) : super(null) {
    _loadCurrentUser();
  }

  final Ref ref;

  void _loadCurrentUser() {
    final authService = ref.read(authServiceProvider);
    state = authService.getCurrentUser();
  }

  void setUser(UserModel? user) {
    state = user;
  }

  Future<void> refreshUser() async {
    _loadCurrentUser();
  }

  Future<void> updateUser(UserModel user) async {
    // Update in database
    final db = DatabaseService();
    await db.saveUser(user);

    // Update state
    state = user;
  }

  void logout() {
    state = null;
  }
}

// Is logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isLoggedIn();
});

// Auth state provider (for loading states during auth operations)
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this.ref) : super(AuthState.initial());

  final Ref ref;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    state = AuthState.loading();

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signUp(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );

      if (result.success) {
        ref.read(currentUserProvider.notifier).setUser(result.user);
        state = AuthState.success(result.message);
      } else {
        state = AuthState.error(result.message);
      }
    } catch (e) {
      state = AuthState.error('An unexpected error occurred');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.login(
        email: email,
        password: password,
      );

      if (result.success) {
        ref.read(currentUserProvider.notifier).setUser(result.user);
        state = AuthState.success(result.message);
      } else {
        state = AuthState.error(result.message);
      }
    } catch (e) {
      state = AuthState.error('An unexpected error occurred');
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();

    try {
      final authService = ref.read(authServiceProvider);
      await authService.logout();
      ref.read(currentUserProvider.notifier).logout();
      state = AuthState.success('Logged out successfully');
    } catch (e) {
      state = AuthState.error('Failed to logout');
    }
  }

  void resetState() {
    state = AuthState.initial();
  }
}

// Auth state class
class AuthState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AuthState({
    required this.isLoading,
    this.error,
    this.successMessage,
  });

  factory AuthState.initial() => AuthState(isLoading: false);
  factory AuthState.loading() => AuthState(isLoading: true);
  factory AuthState.success(String message) => AuthState(isLoading: false, successMessage: message);
  factory AuthState.error(String error) => AuthState(isLoading: false, error: error);
}
