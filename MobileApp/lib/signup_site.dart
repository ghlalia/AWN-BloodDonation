import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../string.dart';
import '../core/session.dart';
import '../core/data_store.dart';
import '../core/models.dart';
import '../account/site_account_screen.dart';
typedef SiteHomeScreen = SiteAccountScreen;

class SignUpSiteScreen extends StatefulWidget {
  const SignUpSiteScreen({super.key});

  @override
  State<SignUpSiteScreen> createState() => _SignUpSiteScreenState();
}

class _SignUpSiteScreenState extends State<SignUpSiteScreen> {
  static const Map<String, Map<String, dynamic>> _centerInfo = {
    'central': {
      'address': 'Riyadh · King Fahad Road',
      'lat': 24.713704,
      'lng': 46.675297,
    },
    'north': {
      'address': 'Riyadh · Al Narjis',
      'lat': 24.885262,
      'lng': 46.653393,
    },
    'south': {
      'address': 'Riyadh · Al Aziziyah',
      'lat': 24.605226,
      'lng': 46.707912,
    },
  };

  final _siteName = TextEditingController();
  final _email = TextEditingController();
  final _contactNumber = TextEditingController();
  final _pass  = TextEditingController();
  String _centerId = 'central';
  bool _show = false;
  bool _loading = false;

  String t(String k) => Strings.t(context, k);

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    final numberRegex = RegExp(r'[0-9]');
    return numberRegex.hasMatch(password);
  }

  bool _validateInputs(String email, String password) {
    if (_siteName.text.trim().isEmpty) {
      _showError(t('siteNameRequired'));
      return false;
    }
    if (_contactNumber.text.trim().isEmpty) {
      _showError(t('contactNumber'));
      return false;
    }
    if (email.isEmpty) {
      _showError(t('emailRequired'));
      return false;
    }
    if (!_isValidEmail(email)) {
      _showError(t('invalidEmail'));
      return false;
    }
    if (password.isEmpty) {
      _showError(t('passwordRequired'));
      return false;
    }
    if (!_isValidPassword(password)) {
      _showError(t('passwordRequirements'));
      return false;
    }
    if (_centerId.isEmpty) {
      _showError(t('centerRequired'));
      return false;
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    final email = _email.text.trim();
    final password = _pass.text;
    if (!_validateInputs(email, password)) return;
    try {
      setState(() => _loading = true);
      final siteName = _siteName.text.trim();
      final contactNumber = _contactNumber.text.trim();
      final siteAddress = (_centerInfo[_centerId]?['address'] as String?) ?? _centerId;
      final selectedLat = (_centerInfo[_centerId]?['lat'] as double?) ?? 0;
      final selectedLng = (_centerInfo[_centerId]?['lng'] as double?) ?? 0;

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await DataStore.instance.createDonationSite(
        siteId: cred.user!.uid,
        email: email,
        name: siteName,
        address: siteAddress,
        contactNumber: contactNumber,
        latitude: selectedLat,
        longitude: selectedLng,
      );

      Session.uid = cred.user!.uid;
      Session.role = 'donation site';
      Session.accountRole = AccountRole.site;
      Session.isLoggedIn = true;
     
      Session.siteCenterId = cred.user!.uid;
      Session.siteContactNumber = contactNumber;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SiteHomeScreen()),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('signUpSite'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: _siteName,
              decoration: InputDecoration(labelText: t('siteName')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _centerId,
              items: const [
                DropdownMenuItem(value: 'central', child: Text('Central')),
                DropdownMenuItem(value: 'north',   child: Text('North')),
                DropdownMenuItem(value: 'south',   child: Text('South')),
              ],
              onChanged: (v) => setState(() => _centerId = v ?? 'central'),
              decoration: InputDecoration(labelText: t('chooseCenter')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: InputDecoration(labelText: t('email')),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactNumber,
              decoration: InputDecoration(labelText: t('contactNumber')),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
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
    );
  }

  @override
  void dispose() {
    _siteName.dispose();
    _email.dispose();
    _contactNumber.dispose();
    _pass.dispose();
    super.dispose();
  }
}
