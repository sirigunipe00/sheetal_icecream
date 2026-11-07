import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sheetal_icecream/app.dart';
import 'package:sheetal_icecream/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase (handles Crashlytics & Core plugins)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // 2. Set system UI overlay
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (_) {}

  // 3. Load .env config
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file load failed ($e). Using default credentials.');
  }

  // 4. Initialize Supabase safely (never crash main() if network or storage is slow)
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'https://kmiuxdaaznmzdbhmrmmh.supabase.co',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_xccq2CosAF1NzVnqBR_KIA_7japKduL',
    );
  } catch (e) {
    debugPrint('Warning: Supabase initialization failed ($e). App will run with offline recovery.');
  }

  try {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (_) {}

  // 5. Global platform error filter for transient network drops
  PlatformDispatcher.instance.onError = (error, stack) {
    final str = error.toString();
    if (str.contains('AuthRetryableFetchException') || str.contains('HandshakeException')) {
      debugPrint('[Network] Handled transient auth token refresh / handshake glitch safely.');
      return true;
    }
    return false;
  };

  // 6. Launch the App - GUARANTEED to execute and paint the UI
  runApp(const SheetalApp());
}
