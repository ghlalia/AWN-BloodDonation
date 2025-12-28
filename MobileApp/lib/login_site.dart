import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../string.dart';
import '../core/session.dart';
import '../core/data_store.dart';
import '../core/auth_state.dart';
import '../account/account_screen.dart';
import 'signup_site.dart';

class LoginSiteScreen extends StatefulWidget {
  const LoginSiteScreen({super.key});

  @override
  State<LoginSiteScreen> createState() => _LoginSiteScreenState();
}

class _LoginSiteScreenState extends State<LoginSiteScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  String _centerId = 'central';

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
      await DataStore.instance.signIn(email: email, password: pass);
      final profile = await DataStore.instance.getCurrentUserProfile();
      if (profile == null) {
        _showError(t('accountNotFound'));
        return;
      }
      final role = (profile['role'] as String?) ?? 'donation site';
      final profileSiteId = profile['siteID'] ??
          profile['siteId'] ??
          profile['siteid'] ??
          profile['siteId'.toLowerCase()] ??
          profile['siteID'.toLowerCase()] ??
          profile['siteId'.toUpperCase()];
     
      final resolvedSiteId = (profileSiteId as String?) ?? FirebaseAuth.instance.currentUser?.uid ?? _centerId;
      setState(() => _centerId = resolvedSiteId);
      Session.siteCenterId = resolvedSiteId;
      Session.siteContactNumber = profile['contactnumber'] as String?;
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
    const siteItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'central', child: Text('Central')),
      DropdownMenuItem(value: 'north', child: Text('North')),
      DropdownMenuItem(value: 'south', child: Text('South')),
    ];
    final safeCenterValue =
        siteItems.any((item) => item.value == _centerId) ? _centerId : null;

    return Scaffold(
      appBar: AppBar(title: Text(t('loginSite'))),
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
                t('loginSiteSubtitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
         
              DropdownButtonFormField<String>(
                value: safeCenterValue,
                items: siteItems,
                onChanged: (v) => setState(() => _centerId = v ?? 'central'),
                decoration: InputDecoration(labelText: t('chooseCenter')),
              ),
              const SizedBox(height: 16),
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
                    MaterialPageRoute(builder: (_) => const SignUpSiteScreen()),
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
