import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../string.dart';
import '../core/session.dart';
import '../core/data_store.dart';
import '../core/auth_state.dart';
import '../account/account_screen.dart';

class SignUpIndividualScreen extends StatefulWidget {
  const SignUpIndividualScreen({super.key});

  @override
  State<SignUpIndividualScreen> createState() => _SignUpIndividualScreenState();
}

class _SignUpIndividualScreenState extends State<SignUpIndividualScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _age   = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  String _bloodType = 'O+';
  bool _show = false;
  bool _loading = false;

  String t(String k) => Strings.t(context, k);

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return t('emailRequired');
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email) || !email.toLowerCase().endsWith('.com')) {
      return 'Please enter a valid email ending with .com';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return t('passwordRequired');
    final strong = RegExp(r'^(?=.*[A-Za-z])(?=.*[!@#\$&*~_]).{8,}$');
    if (!strong.hasMatch(password)) {
      return 'Password must be at least 8 characters and include a letter and special character.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final raw = value ?? '';
    final digits = raw.replaceAll(RegExp(r'\s+'), '');
    if (digits.isEmpty) return t('phoneNumber');
    final startsWith05 = digits.startsWith('05');
    final startsWith5 = digits.startsWith('5');
    final validLength = (startsWith05 && digits.length == 10) || (startsWith5 && digits.length == 9);
    if (!startsWith05 && !startsWith5 || !validLength) {
      return 'Please enter a valid Saudi mobile number starting with 05 or 5 (9–10 digits).';
    }
    return null;
  }

  String? _validateAge(String? value) {
    final ageVal = int.tryParse((value ?? '').trim());
    if (ageVal == null) return t('age');
    if (ageVal < 18) return 'You must be 18 or older to register.';
    return null;
  }

  Future<void> _handleSubmit() async {
    final email = _email.text.trim();
    final password = _pass.text;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Ensure email is not registered
    final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    if (methods.isNotEmpty) {
      _showError('This email is already registered');
      return;
    }
    try {
      setState(() => _loading = true);
      final age = int.parse(_age.text.trim());
      final cred = await DataStore.instance.signUpDonor(
        name: _name.text.trim(),
        email: email,
        password: password,
        age: age,
        phone: _phone.text.trim(),
        location: _location.text.trim(),
        bloodType: _bloodType,
      );
      final profile = await DataStore.instance.getCurrentUserProfile();
      if (profile == null) {
        _showError(t('accountNotFound'));
        return;
      }
      await AuthState.refreshSessionRole(
        role: 'donor',
        profile: profile,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AccountScreen(role: Session.accountRole)),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Auth error');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _age.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('signUpDonor'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: t('name')),
                validator: (v) => (v?.trim().isEmpty ?? true) ? t('nameRequired') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: t('email')),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: !_show,
                decoration: InputDecoration(
                  labelText: t('password'),
                  suffixIcon: IconButton(
                    icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _show = !_show),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t('age')),
                validator: _validateAge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t('phoneNumber')),
                validator: _validatePhone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                decoration: InputDecoration(labelText: t('location')),
                validator: (v) => (v?.trim().isEmpty ?? true) ? t('location') : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _bloodType,
                items: const [
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                ],
                onChanged: (v) => setState(() => _bloodType = v ?? 'O+'),
                decoration: InputDecoration(labelText: t('bloodType')),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _handleSubmit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t('signUp')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
