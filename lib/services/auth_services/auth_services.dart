import 'package:supabase_flutter/supabase_flutter.dart';

class AuthServices {
  final SupabaseClient _supabase = Supabase.instance.client;

  //signin Email and password
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // ✅ Step 1: Check if email already exists in `profiles` table
      final existingUser = await _supabase
          .from('profiles')
          .select('id, email')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        print("⚠️ Email already registered: $email");

        // (Optional) Resend confirmation email
        try {
          await _supabase.auth.resend(type: OtpType.signup, email: email);
          print("📩 Confirmation email resent to $email");
        } catch (resendErr) {
          print("⚠️ Failed to resend confirmation email: $resendErr");
        }

        throw Exception("This email is already registered. Please login.");
      }

      // ✅ Step 2: Proceed with signup
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: "dopashorts://email-confirm", // deep link
      );

      final user = response.user;
      if (user != null) {
        print("📩 Signup successful. Verification email sent to ${user.email}");
        print(
          "⏳ Waiting for user to confirm email before inserting into profiles table.",
        );
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Signup failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  //Signout
  Future<void> signOut() async {
    return await _supabase.auth.signOut();
  }

  //get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  //forgot password
  Future<void> forgotPassword(String email) async {
    return await _supabase.auth.resetPasswordForEmail(email);
  }
}
