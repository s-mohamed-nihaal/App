import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return ref.watch(authRepositoryProvider).getProfile();
});

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signUp({
    required String email, 
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        // ignore: use_null_aware_elements
        if (fullName != null) 'full_name': fullName,
        // ignore: use_null_aware_elements
        if (phone != null) 'phone': phone,
      },
    );

    return response;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      throw AuthException('Connection timed out. Please check your network.', statusCode: '408');
    });
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
