import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../string.dart';
import '../core/session.dart';

class EditDonorProfileScreen extends StatefulWidget {
  const EditDonorProfileScreen({super.key});

  @override
  State<EditDonorProfileScreen> createState() => _EditDonorProfileScreenState();
}

class _EditDonorProfileScreenState extends State<EditDonorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _password = TextEditingController();
  String _bloodType = 'O+';
  bool _loading = true;
  bool _saving = false;

  String t(String k) => Strings.t(context, k);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cached = Session.profile;
    if (cached != null) {
      _fillFromMap(cached);
      setState(() => _loading = false);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? Session.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('donors').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        Session.profile = data;
        _fillFromMap(data);
      }
    } catch (_) {
      
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillFromMap(Map<String, dynamic> data) {
    _name.text = (data['name'] as String?) ?? '';
    final ageVal = (data['age'] as num?)?.toInt();
    _age.text = ageVal != null ? ageVal.toString() : '';
    _email.text = (data['email'] as String?) ?? '';
    _phone.text = (data['Phone'] as String?) ?? '';
    _location.text = (data['location'] as String?) ?? '';
    _bloodType = (data['bloodtype'] as String?) ?? _bloodType;
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
    if (password.isEmpty) return null;
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

  Future<void> _handleSave() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final ageVal = int.tryParse(_age.text.trim());
    final phone = _phone.text.trim();
    final location = _location.text.trim();
    final password = _password.text;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? Session.uid;
    if (uid == null) return;

    final currentEmail = FirebaseAuth.instance.currentUser?.email;
    if (email.toLowerCase() != (currentEmail ?? '').toLowerCase()) {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        _showSnack('This email is already registered');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      if (email.toLowerCase() != (currentEmail ?? '').toLowerCase()) {
        await FirebaseAuth.instance.currentUser?.updateEmail(email);
      }
      if (password.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updatePassword(password);
      }
      await FirebaseFirestore.instance.collection('donors').doc(uid).set({
        'name': name,
        'email': email,
        'age': ageVal,
        'Phone': phone,
        'location': location,
        'bloodtype': _bloodType,
      }, SetOptions(merge: true));

      Session.profile = {
        ...(Session.profile ?? {}),
        'name': name,
        'email': email,
        'age': ageVal,
        'Phone': phone,
        'location': location,
        'bloodtype': _bloodType,
      };

      if (!mounted) return;
      _showSnack(t('profileUpdated'));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _showSnack(t('errorOccurred'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _age.dispose();
    _phone.dispose();
    _location.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('editProfile'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t('email')),
                validator: _validateEmail,
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
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (optional)'),
                validator: _validatePassword,
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
                onChanged: (v) => setState(() => _bloodType = v ?? _bloodType),
                decoration: InputDecoration(labelText: t('bloodType')),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _handleSave,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t('save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
