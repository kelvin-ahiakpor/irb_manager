import 'package:supabase_flutter/supabase_flutter.dart';

// Single access point for the Supabase client throughout the app.
// Initialised once in main.dart via SupabaseConfig.initialize().
SupabaseClient get supabase => Supabase.instance.client;

class SupabaseConfig {
  static const String url = 'https://tznryskacildjctzznpe.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6bnJ5c2thY2lsZGpjdHp6bnBlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2ODcyNTIsImV4cCI6MjA5MTI2MzI1Mn0.kkwxDsl2cJx90fMQSrDVq0dHMTm__YqqqasPbDu-2UA';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}
