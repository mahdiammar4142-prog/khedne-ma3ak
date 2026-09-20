import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lebanon_places/features/auth/data/auth_repository.dart';
import 'package:lebanon_places/features/auth/data/user_profile_model.dart';
import 'package:lebanon_places/features/auth/data/user_profile_repository.dart';

const _teal = Color(0xFF00A651);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthRepository();
  final _profileRepo = UserProfileRepository();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  static const _blue = Color(0xFF2196F3);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Fill in all fields');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user != null) {
        await user.updateDisplayName(name);
        final now = DateTime.now();
        String handle;
        try {
          handle = await _profileRepo.generateUniqueHandle(name);
        } catch (_) {
          final safeBase = name
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
              .replaceAll(RegExp(r'_+'), '_')
              .replaceAll(RegExp(r'^_|_$'), '');
          final base = safeBase.isEmpty ? 'user' : safeBase;
          final suffix = user.uid.length >= 6 ? user.uid.substring(0, 6) : user.uid;
          handle = '${base}_$suffix';
        }
        final profile = UserProfileModel(
          id: user.uid,
          displayName: name,
          handle: handle,
          email: user.email ?? email,
          photoUrl: user.photoURL,
          createdAt: now,
          updatedAt: now,
        );
        try {
          await _profileRepo.createProfile(profile);
        } catch (_) {}
        try {
          await _profileRepo.ensureProfileExists(
            userId: user.uid,
            displayName: name,
            email: user.email ?? email,
            photoUrl: user.photoURL,
          );
        } catch (_) {}
      }
      if (mounted) context.go('/home');
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst(RegExp(r'^\[.*\]\s*'), '');
        _loading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade800),
          onPressed: () => context.go('/gate'),
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Join Khedne Ma3ak',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _AuthTextField(
                controller: _name,
                label: 'Username',
                hint: 'This can be reused by others',
                icon: Icons.person_outline_rounded,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
              _AuthTextField(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
              _AuthTextField(
                controller: _password,
                label: 'Password (min 6 characters)',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 28),
              _AuthButton(
                label: 'Create Account',
                color: _teal,
                onPressed: _loading ? null : _submit,
                loading: _loading,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loading ? null : () => context.pop(),
                child: const Text(
                  'Already have an account? Sign in',
                  style: TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const _AuthTextField({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _teal, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      onChanged: onChanged,
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool loading;

  const _AuthButton({
    required this.label,
    required this.color,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 2),
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
