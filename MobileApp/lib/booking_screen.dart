import 'dart:async'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../string.dart';
import '../core/data_store.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/ble_service.dart'; 

class BookingScreen extends StatefulWidget {
  final String centerId;
  final String centerName;
  const BookingScreen({super.key, required this.centerId, required this.centerName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Vitals? _vitals;
  bool _loadingVitals = true; 
  EligibilityResult? _eligibility;
  StreamSubscription? _bleSubscription; 

  String t(String key) => Strings.t(context, key);

  @override
  void initState() {
    super.initState();
    BleService.I.connect();
    _bleSubscription = BleService.I.dataStream.listen((data) {
       // data is hr, ox, sys, dia
       if (mounted) {
         final newVitals = Vitals(
             pulse: data[0],
             oxygenLevel: data[1],
             systolic: data[2],
             diastolic: data[3],
             heartRate: data[0],
          
         );

         // check eligibility instantly with new numbers
         final age = (Session.profile?['age'] as num?)?.toInt() ?? 0;
         final newElig = DataStore.I.checkEligibility(age: age, vitals: newVitals);

         setState(() {
           _vitals = newVitals;
           _eligibility = newElig;
           _loadingVitals = false; // Stop loading spinner once we have data
         });
       }
    });

    
    _loadCachedVitals();
  }

  @override
  void dispose() {
    _bleSubscription?.cancel(); //  Stops listening when leaving screen
    super.dispose();
  }

 
  Future<void> _loadCachedVitals() async {
    final age = (Session.profile?['age'] as num?)?.toInt();
    if (age == null) return;

    try {
      final v = await DataStore.I.readVitalsFromBracelet();
      if (v.pulse > 0) {
        final elig = DataStore.I.checkEligibility(age: age, vitals: v);
        if (mounted) {
          setState(() {
            _vitals = v;
            _eligibility = elig;
            _loadingVitals = false;
          });
        }
      }
    } catch (_) {

    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DataStore.I;

    return Scaffold(
      appBar: AppBar(title: Text(t('bookAppointment'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            
            Text(widget.centerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            // Shortages 
            _buildShortagesBanner(),

            const SizedBox(height: 16),

            // Vitals Section 
            _vitalsSection(),

            const Divider(height: 32),

            // Date & Time
            _dateTimePickers(),

            const SizedBox(height: 12),

            // Confirm Button
            ElevatedButton(
              onPressed: () async {
                if (_selectedDate == null || _selectedTime == null) {
                  _showSnack(t('pleasePickDateTime'));
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  _showSnack('Please sign in first');
                  return;
                }

                final profile = Session.profile;
                if (profile == null) {
                  _showSnack(t('loginDonor'));
                  return;
                }

                final age = (profile['age'] as num?)?.toInt() ?? 0;
                if (age < 18) {
                  _showDialog(t('notEligible'), t('ageRestriction'));
                  return;
                }

                // Check Eligibility
                final vitals = _vitals;
                if (vitals == null || vitals.pulse == 0) {
                  _showSnack(t('readVitalsFirst'));
                  return;
                }
                
                // Double check eligibility before booking
                final elig = ds.checkEligibility(age: age, vitals: vitals);
                if (!elig.ok) {
                  _showDialog(t('notEligible'), t(elig.reasonKey ?? 'notEligible'));
                  return;
                }

                // Create Appointment
                final dt = DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                  _selectedTime!.hour,
                  _selectedTime!.minute,
                );
                final selectedSiteId = widget.centerId;
                final selectedSiteName = widget.centerName;
                final donorBloodType = profile['bloodtype'] as String? ?? 'O+';
                final donorName = profile['name'] as String? ?? 'Test Donor';

                final existingUpcoming = await FirebaseFirestore.instance
                    .collection('donors')
                    .doc(user.uid)
                    .collection('donorappointments')
                    .where('status', isEqualTo: 'upcoming')
                    .limit(1)
                    .get();
                if (existingUpcoming.docs.isNotEmpty) {
                  await _showDialog(
                    t('existingAppointmentTitle'),
                    t('existingAppointmentMessage'),
                  );
                  return;
                }

                try {
                  await DataStore.instance.bookAppointment(
                    donorId: user.uid,
                    donorName: donorName,
                    donorBloodType: donorBloodType,
                    siteId: selectedSiteId,
                    siteName: selectedSiteName,
                    dateTime: dt,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('bookedSuccessfully'))),
                  );
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!mounted) return;
                  debugPrint('Book appointment error: $e');
                  _showSnack(t('errorOccurred'));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(t('confirm')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t('vitals'), style: const TextStyle(fontWeight: FontWeight.w700)),
                // Show a small "Live" indicator if connected
                if (BleService.I.isConnected)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)),
                    child: Text("LIVE", style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            const SizedBox(height: 8),
            
         
            if (_loadingVitals && _vitals == null) 
              const LinearProgressIndicator(minHeight: 4),
              
            if (_loadingVitals && _vitals == null) 
              const SizedBox(height: 8),
              
            if (_vitals != null)
              Text(
                'BP ${_vitals!.systolic}/${_vitals!.diastolic} · HR ${_vitals!.pulse} · O2 ${_vitals!.oxygenLevel ?? '-'}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              
            if (_eligibility != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _eligibility!.ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _eligibility!.ok ? t('donationSafe') : t('donationUnsafe'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _eligibility!.ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                    ),
                    if (!_eligibility!.ok) ...[
                      const SizedBox(height: 6),
                      Text(
                        _eligibility!.reasonKey != null
                            ? t(_eligibility!.reasonKey!)
                            : t('donationUnsafeDetails'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateTimePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('pickDateTime'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: now.add(const Duration(days: 1)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 60)),
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
                child: Text(_selectedDate == null ? t('pickDate') : '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final tOf = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
                  if (tOf != null) setState(() => _selectedTime = tOf);
                },
                child: Text(_selectedTime == null ? t('pickTime') : _selectedTime!.format(context)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortagesBanner() {
    final list = DataStore.I.shortages(widget.centerId);
    if (list.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('${t('shortages')}: ${list.join(', ')}'),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showDialog(String title, String content) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('ok')),
          ),
        ],
      ),
    );
  }
}
