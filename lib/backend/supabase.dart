import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Single access point for the Supabase client throughout the app.
// Initialised once in main.dart via SupabaseConfig.initialize().
SupabaseClient get supabase => Supabase.instance.client;

class SupabaseConfig {
  static const String url = 'https://tznryskacildjctzznpe.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6bnJ5c2thY2lsZGpjdHp6bnBlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2ODcyNTIsImV4cCI6MjA5MTI2MzI1Mn0.kkwxDsl2cJx90fMQSrDVq0dHMTm__YqqqasPbDu-2UA';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        pkceAsyncStorage: _LoggingPkceStorage(),
      ),
    );
  }
}

class _LoggingPkceStorage extends GotrueAsyncStorage {
  _LoggingPkceStorage() {
    _initialize();
  }

  final Completer<void> _initializationCompleter = Completer<void>();
  late final SharedPreferences _prefs;

  Future<void> _initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    _prefs = await SharedPreferences.getInstance();
    _initializationCompleter.complete();
  }

  Future<SharedPreferences> get _storage async {
    await _initializationCompleter.future;
    return _prefs;
  }

  @override
  Future<String?> getItem({required String key}) async {
    final value = (await _storage).getString(key);
    debugPrint('Supabase PKCE getItem key=$key present=${value != null}');
    return value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    debugPrint('Supabase PKCE removeItem key=$key');
    await (await _storage).remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    debugPrint('Supabase PKCE setItem key=$key length=${value.length}');
    await (await _storage).setString(key, value);
  }
}
