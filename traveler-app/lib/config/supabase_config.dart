import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get hasValidCredentials {
    final url = supabaseUrl.trim();
    final key = supabaseAnonKey.trim();
    return url.isNotEmpty &&
        !url.contains('your-project-id') &&
        key.isNotEmpty &&
        !key.contains('your-supabase-anon-key');
  }

  /// Safely initializes Supabase client if valid credentials exist.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (hasValidCredentials) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        _isInitialized = true;
      } catch (e) {
        // Fallback for tests or offline modes
        _isInitialized = false;
      }
    }
  }

  /// Helper to get Supabase client instance safely.
  static SupabaseClient? get client {
    if (_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
