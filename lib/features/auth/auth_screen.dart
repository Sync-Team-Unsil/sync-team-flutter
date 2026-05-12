import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _userCtrl.dispose();
    _confirmCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _roleCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (_isLogin) {
      final res = await ref.read(profileProvider.notifier).signIn(email, password);
      if (mounted) {
        setState(() => _isLoading = false);
        if (res != null) {
          setState(() => _error = res);
        } else {
          context.go('/home');
        }
      }
    } else {
      final username = _userCtrl.text.trim();
      final confirm = _confirmCtrl.text;
      if (password != confirm) {
        setState(() {
          _error = "Passwords don't match";
          _isLoading = false;
        });
        return;
      }
      final res = await ref.read(profileProvider.notifier).signUp(
        email: email,
        password: password,
        username: username,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        role: _roleCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (res != null) {
          setState(() => _error = res);
        } else {
          context.go('/home');
        }
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: Colors.white,
      body: isWide ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  // ─── WEB LAYOUT (Node 1:2721 & 1:2819) ───
  Widget _buildWebLayout() {
    return Row(
      children: [
        // Left: Image with text overlay
        Expanded(
          flex: 1,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/imgloginregister.png',
                  fit: BoxFit.cover,
                ),
              ),
              // Shadow overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Text overlay
              Positioned(
                left: 48,
                bottom: 80,
                right: 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync your team with SyncTeam',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.72,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The best platform to manage and collaborate with your team efficiently.',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Right: Form
        Expanded(
          flex: 1,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(64),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── MOBILE LAYOUT ───
  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: _buildForm(),
      ),
    );
  }

  // ─── FORM ───
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo (Node 1:2730)
        Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Text(
              'SyncTeam',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Title & Subtitle (Node 1:2734)
        Text(
          _isLogin ? 'Welcome Back' : 'Welcome to SyncTeam',
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isLogin
              ? 'Please enter your username and password.'
              : 'Create an account for using sync team, please enter your personal information',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),

        // Error message
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
          const SizedBox(height: 16),
        ],

        // Form Fields (Node 1:2738)
        if (!_isLogin) ...[
          Row(
            children: [
              Expanded(child: _buildField('First Name', _firstNameCtrl, 'First name')),
              const SizedBox(width: 16),
              Expanded(child: _buildField('Last Name', _lastNameCtrl, 'Last name')),
            ],
          ),
          const SizedBox(height: 16),
          _buildField('Username', _userCtrl, 'Please input your Username'),
          const SizedBox(height: 16),
          _buildField('Role', _roleCtrl, 'e.g. Front-end Developer'),
          const SizedBox(height: 16),
          _buildField('Bio', _bioCtrl, 'Short description about you', maxLines: 3),
          const SizedBox(height: 16),
        ],

        _buildField(
          _isLogin ? 'Username' : 'Email',
          _emailCtrl,
          _isLogin ? 'Please input your Username' : 'Please input your Email',
          type: _isLogin ? null : TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        _buildField('Password', _passCtrl, 'Please input your Password', obscure: true),

        if (!_isLogin) ...[
          const SizedBox(height: 16),
          _buildField('Confirm Password', _confirmCtrl, 'Please input your Password again', obscure: true),
        ],

        const SizedBox(height: 40),

        // Submit Button (Node 1:2766)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(_isLogin ? 'Login' : 'Register'),
          ),
        ),
        const SizedBox(height: 12),

        // Toggle Link (Node 1:2768)
        Center(
          child: GestureDetector(
            onTap: _toggleMode,
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSubtext2),
                children: [
                  TextSpan(text: _isLogin ? "don't have an account, " : 'already have account, '),
                  TextSpan(
                    text: _isLogin ? 'register' : 'login',
                    style: const TextStyle(color: AppColors.textLink, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {TextInputType? type, bool obscure = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
