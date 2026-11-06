import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

enum _AuthMode { signIn, signUp }

class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({
    super.key,
    this.onSuccess,
    this.title,
    this.subtitle,
  });

  final VoidCallback? onSuccess;
  final String? title;
  final String? subtitle;

  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onSuccess,
    String? title,
    String? subtitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuthBottomSheet(
        onSuccess: onSuccess,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  /// Checks if the user is already signed in. If yes, calls [onAuthenticated].
  /// If not, opens [AuthBottomSheet]. Once signed in or signed up,
  /// calls [onAuthenticated].
  static Future<bool> requireAuth(
    BuildContext context, {
    required VoidCallback onAuthenticated,
    String? title,
    String? subtitle,
  }) async {
    if (SupabaseService.instance.isSignedIn) {
      onAuthenticated();
      return true;
    }
    final res = await show(
      context,
      onSuccess: onAuthenticated,
      title: title,
      subtitle: subtitle,
    );
    return res == true;
  }

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;
  String? _infoMessage;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _setMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
      _infoMessage = null;
      _loading = false;
    });
  }

  bool _validEmail(String email) => email.contains('@') && email.contains('.');

  Future<void> _submit() => _signInOrUp();

  Future<void> _signInOrUp() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (!_validEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      if (_isSignUp) {
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
          data: _nameCtrl.text.trim().isNotEmpty
              ? {'display_name': _nameCtrl.text.trim()}
              : null,
        );
        if (res.user == null) {
          throw const AuthException('Sign up failed. Please try again.');
        }
        if (res.session == null) {
          if (!mounted) return;
          setState(() {
            _mode = _AuthMode.signIn;
            _infoMessage =
                'We sent a verification email to $email. Open it, then sign in.';
            _passwordCtrl.clear();
          });
          return;
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSignUp ? 'Account created successfully!' : 'Signed in successfully!',
            ),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _header()),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.softMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) _banner(_errorMessage!, isError: true),
            if (_infoMessage != null) _banner(_infoMessage!, isError: false),
            ..._fields(),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _buttonLabel,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final defaultHeader = switch (_mode) {
      _AuthMode.signUp => (
          'Create Account',
          'Sign up to save items, place orders and track delivery',
        ),
      _AuthMode.signIn => (
          'Welcome to Sheetal',
          'Sign in to add items to your cart & wishlist',
        ),
    };

    final title = widget.title ?? defaultHeader.$1;
    final subtitle = widget.subtitle ?? defaultHeader.$2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.royalPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.softMuted),
        ),
      ],
    );
  }

  List<Widget> _fields() {
    switch (_mode) {
      case _AuthMode.signUp:
        return [
          _textField(
            controller: _nameCtrl,
            label: 'Your Name',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          _emailField(),
          const SizedBox(height: 14),
          _passwordField(),
        ];
      case _AuthMode.signIn:
        return [
          _emailField(),
          const SizedBox(height: 14),
          _passwordField(),
        ];
    }
  }

  Widget _footer() {
    return Center(
      child: TextButton(
        onPressed: _loading
            ? null
            : () => _setMode(_isSignUp ? _AuthMode.signIn : _AuthMode.signUp),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: AppColors.softMuted),
            children: [
              TextSpan(
                text: _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
              ),
              TextSpan(
                text: _isSignUp ? 'Sign In' : 'Sign Up',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _buttonLabel {
    return _isSignUp ? 'Create Account' : 'Sign In';
  }

  Widget _emailField() {
    return _textField(
      controller: _emailCtrl,
      label: 'Email Address',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _passwordField() {
    return _textField(
      controller: _passwordCtrl,
      label: 'Password',
      icon: Icons.lock_outline_rounded,
      obscure: _obscurePassword,
      suffix: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: Colors.grey,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.borderPink),
    );
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFFF8FC),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _banner(String message, {required bool isError}) {
    final color = isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
    final background = isError ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final border = isError ? const Color(0xFFEF9A9A) : const Color(0xFFA5D6A7);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.mark_email_read_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
