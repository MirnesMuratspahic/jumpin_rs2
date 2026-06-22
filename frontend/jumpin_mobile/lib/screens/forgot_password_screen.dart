import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final String? initialEmail;

  const ForgotPasswordScreen({
    super.key,
    required this.authProvider,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color _primaryColor = Color(0xFF1565C0);

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  bool _codeSent = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) _emailController.text = widget.initialEmail!;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await widget.authProvider.requestPasswordReset(_emailController.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _codeSent = true;
    });
    _snack('If an account with that email exists, a reset code has been sent.',
        success: true);
  }

  Future<void> _reset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final error = await widget.authProvider.resetPassword(
      _emailController.text.trim(),
      _codeController.text.trim(),
      _newController.text,
      _confirmController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error == null) {
      _snack('Password reset. You can now log in.', success: true);
      Navigator.of(context).pop();
    } else {
      _snack(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _codeSent ? _buildResetStep() : _buildEmailStep(),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Icon(Icons.lock_reset, size: 72, color: _primaryColor),
          const SizedBox(height: 16),
          const Text(
            'Enter your email and we will send you a 6-digit reset code.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              final emailRegex = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Enter a valid email (e.g. user@example.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _primaryButton('Send code', _sendCode),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Icon(Icons.mark_email_read, size: 72, color: _primaryColor),
          const SizedBox(height: 16),
          Text(
            'Enter the code sent to ${_emailController.text.trim()} and choose a new password.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Reset code',
              prefixIcon: const Icon(Icons.pin),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) =>
                (v == null || v.trim().length != 6) ? 'Enter the 6-digit code' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'At least 6 characters' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) =>
                (v != _newController.text) ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          _primaryButton('Reset password', _reset),
          TextButton(
            onPressed: _loading ? null : _sendCode,
            child: const Text('Resend code'),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
