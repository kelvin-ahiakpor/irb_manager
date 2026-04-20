import 'package:supabase_flutter/supabase_flutter.dart';

// Single access point for the Supabase client throughout the app.
// Initialised once in main.dart via SupabaseConfig.initialize().
SupabaseClient get supabase => Supabase.instance.client;

class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tznryskacildjctzznpe.supabase.co',
  );
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> initialize() async {
    if (anonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_ANON_KEY. Run Flutter with '
        '--dart-define=SUPABASE_ANON_KEY=<anon-key>.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
}
