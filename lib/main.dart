import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sheetal_icecream/app.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file load failed ($e). Using default credentials.');
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'https://kmiuxdaaznmzdbhmrmmh.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_xccq2CosAF1NzVnqBR_KIA_7japKduL',
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  PlatformDispatcher.instance.onError = (error, stack) {
    final str = error.toString();
    if (str.contains('AuthRetryableFetchException') || str.contains('HandshakeException')) {
      debugPrint('[Network] Handled transient auth token refresh / handshake glitch safely.');
      return true;
    }
    return false;
  };

  runApp(const SheetalApp());
}
