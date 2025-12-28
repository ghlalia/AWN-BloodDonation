import 'package:flutter/material.dart';
import '../string.dart';
import '../core/session.dart';
import '../core/data_store.dart';
import '../core/auth_state.dart';
import '../account/account_screen.dart';
import 'signup_individual.dart';

class LoginIndividualScreen extends StatefulWidget {
  const LoginIndividualScreen({super.key});

  @override
  State<LoginIndividualScreen> createState() => _LoginIndividualScreenState();
}

class _LoginIndividualScreenState extends State<LoginIndividualScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _show = false;
  bool _loading = false;

  String t(String k) => Strings.t(context, k);

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _attemptLogin() async {
    final email = _email.text.trim();
    final pass = _pass.text;

    try {
      setState(() => _loading = true);
      await DataStore.instance.signIn(
        email: email,
        password: pass,
      );
      final profile = await DataStore.instance.getCurrentUserProfile();
      if (profile == null) {
        _showError(t('accountNotFound'));
        return;
      }
      final role = (profile['role'] as String?) ?? 'donor';
      if (role == 'donation site') {
        Session.siteCenterId = profile['siteID'] as String?;
        Session.siteContactNumber = profile['contactnumber'] as String?;
      }
      await AuthState.refreshSessionRole(
        role: role,
        profile: profile,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AccountScreen(role: Session.accountRole)),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('loginDonor'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 96,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                t('loginDonorSubtitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t('email')),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pass,
                obscureText: !_show,
                decoration: InputDecoration(
                  labelText: t('password'),
                  suffixIcon: IconButton(
                    icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _show = !_show),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _attemptLogin,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t('loginButton')),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpIndividualScreen()),
                  );
                  if (ok == true) Navigator.pop(context, true);
                },
                child: Text(t('noAccountSignUp')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }
}
