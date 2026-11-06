import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sheetal_icecream/data/admin/admin_repository.dart';
import 'package:sheetal_icecream/features/admin/presentation/admin_shell.dart';
import 'package:sheetal_icecream/features/shell/presentation/app_shell.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

/// Picks customer shop vs admin panel based on the signed-in user's role.
class SessionRoot extends StatefulWidget {
  const SessionRoot({super.key});

  @override
  State<SessionRoot> createState() => _SessionRootState();
}

class _SessionRootState extends State<SessionRoot> {
  final _adminRepo = AdminRepository();
  StreamSubscription<AuthState>? _authSub;

  bool _loading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _resolve();
    if (SupabaseGate.ready) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        _resolve();
      });
    }
  }

  Future<void> _resolve() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final admin = await _adminRepo.amIAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isAdmin) return const AdminShell();
    return const AppShell();
  }
}
