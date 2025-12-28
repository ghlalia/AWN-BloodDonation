import 'dart:async'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../string.dart';
import '../core/data_store.dart';
import '../core/models.dart';
import '../core/session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/ble_service.dart'; 
import 'edit_donor_profile_screen.dart';

class UserAccountScreen extends StatefulWidget {
  const UserAccountScreen({super.key});

  @override
  State<UserAccountScreen> createState() => _UserAccountScreenState();
}

class _UserAccountScreenState extends State<UserAccountScreen> {
  String t(String k) => Strings.t(context, k);
  bool _readingVitals = false;
  int? _systolic;
  int? _diastolic;
  int? _oxygenLevel;
  Vitals? _braceletVitals;
  EligibilityResult? _eligibility;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _upcomingApptStream;
  Timer? _dbSaveTimer;
  StreamSubscription? _bleSubscription;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? Session.uid;
    if (uid != null) {
      _upcomingApptStream = FirebaseFirestore.instance
          .collection('donors')
          .doc(uid)
          .collection('donorappointments')
          .orderBy('date', descending: false)
          .snapshots()
          .asBroadcastStream();
    }
    _loadData();
    
    // 1. Connect BLE
    BleService.I.connect();

    // 2. LISTEN TO STREAM (Fixes Real-time issues)
    _bleSubscription = BleService.I.dataStream.listen((data) {
       if (mounted) {
         setState(() {
           _braceletVitals = Vitals(
             pulse: data[0],
             oxygenLevel: data[1],
             systolic: data[2],
             diastolic: data[3],
             heartRate: data[0],
            
           );
           final age = (Session.profile?['age'] as num?)?.toInt();
           if (age != null) {
             _eligibility = DataStore.I.checkEligibility(age: age, vitals: _braceletVitals!);
           }
         });
       }
    });

    // 3. DATABASE SAVE (Fixes Timer Error)
    _dbSaveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _saveVitalsToDatabase();
      }
    });
  }

  @override
  void dispose() {
    _dbSaveTimer?.cancel();
    _bleSubscription?.cancel();
    super.dispose();
  }

  Future<void> _saveVitalsToDatabase() async {
    final uid = Session.uid;
    if (uid == null || _braceletVitals == null) return;
    
    // Only save if data is valid (>0)
    if (_braceletVitals!.pulse > 0 && _braceletVitals!.oxygenLevel != null) {
       try {
         await DataStore.instance.addDonorVitals(
            uid: uid,
            systolic: _braceletVitals!.systolic,
            diastolic: _braceletVitals!.diastolic,
            heartRate: _braceletVitals!.pulse,
            oxygenLevel: _braceletVitals!.oxygenLevel!,
            timestamp: DateTime.now(),
          );
       } catch (e) {
         print("DB Save Error: $e");
       }
    }
  }

  Future<void> _loadData() async {
    final uid = Session.uid;
    if (uid == null) return;
    try {
      final vitalsSnap = await FirebaseFirestore.instance
          .collection('donors')
          .doc(uid)
          .collection('vitals')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (vitalsSnap.docs.isNotEmpty) {
        final v = vitalsSnap.docs.first.data();
        setState(() {
          _systolic = (v['systolic'] as num?)?.toInt();
          _diastolic = (v['diastolic'] as num?)?.toInt();
          _oxygenLevel = (v['oxygenlevel'] as num?)?.toInt();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
      final profile = Session.profile;
      final user = UserProfile(
        name: (profile?['name'] as String?) ?? 'Guest',
        age: (profile?['age'] as num?)?.toInt() ?? 20,
        bloodType: (profile?['bloodtype'] as String?) ?? 'O+',
        phone: profile?['Phone'] as String?,
        location: profile?['location'] as String?,
      );

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _summaryCard(user),
          const SizedBox(height: 16),
          _vitalsCard(),
          const SizedBox(height: 16),
          _appointmentsCard(),
        ],
      );
  }

  Widget _vitalsCard() {
    final liveVitals = _braceletVitals;
    final systolic = liveVitals?.systolic ?? _systolic ?? 0;
    final diastolic = liveVitals?.diastolic ?? _diastolic ?? 0;
    final heartRate = liveVitals?.pulse ?? liveVitals?.heartRate ?? 0;
    final oxygen = liveVitals?.oxygenLevel ?? _oxygenLevel ?? 0;
    final eligibility = _eligibility;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('vitals'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _metricRow(
                  icon: Icons.monitor_heart,
                  label: 'Blood pressure',
                  value: 'BP $systolic/$diastolic',
                  color: const Color(0xFFC62828),
                ),
                const SizedBox(height: 10),
                _metricRow(
                  icon: Icons.favorite_border,
                  label: 'Heart rate',
                  value: heartRate > 0 ? '$heartRate bpm' : '—',
                  color: const Color(0xFF1565C0),
                ),
                const SizedBox(height: 10),
                _metricRow(
                  icon: Icons.water_drop_outlined,
                  label: 'Oxygen',
                  value: '$oxygen %',
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _eligibilityStatus(eligibility),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _summaryCard(UserProfile user) {
     final subtitle = (user.location?.isNotEmpty ?? false) ? user.location! : '';
     return Card(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       child: Padding(
         padding: const EdgeInsets.all(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   CircleAvatar(
                     radius: 28,
                     backgroundColor: const Color(0xFFE3F2FD),
                     child: Text(
                       user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                       style: const TextStyle(
                         color: Color(0xFF1565C0),
                         fontWeight: FontWeight.w700,
                         fontSize: 20,
                       ),
                     ),
                   ),
                   const SizedBox(width: 14),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           user.name,
                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                         ),
                         if (subtitle.isNotEmpty) ...[
                           const SizedBox(height: 4),
                           Text(
                             subtitle,
                             style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                           ),
                         ],
                       ],
                     ),
                   ),
                   Column(
                     mainAxisSize: MainAxisSize.min,
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         decoration: BoxDecoration(
                           color: const Color(0xFFFFEBEE),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const Icon(Icons.water_drop, size: 16, color: Color(0xFFC62828)),
                             const SizedBox(width: 6),
                             Text(
                               user.bloodType,
                               style: const TextStyle(
                                 fontWeight: FontWeight.w700,
                                 color: Color(0xFFC62828),
                               ),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 6),
                       TextButton.icon(
                         onPressed: () async {
                           await Navigator.push(
                             context,
                             MaterialPageRoute(builder: (_) => const EditDonorProfileScreen()),
                           );
                           if (!mounted) return;
                           setState(() {});
                         },
                         icon: const Icon(Icons.edit, size: 16),
                         label: Text(t('editProfile')),
                         style: TextButton.styleFrom(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           minimumSize: const Size(0, 0),
                         ),
                       ),
                     ],
                   ),
                 ],
               ),
           const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (user.location != null && user.location!.isNotEmpty)
                  _infoChip(Icons.place_outlined, user.location!),
                _infoChip(Icons.cake_outlined, '${t('age')}: ${user.age}'),
              ],
            ),
          ],
        ),
      ),
     ); 
  }
  Widget _appointmentsCard() {
     if (_upcomingApptStream == null) {
       return Card(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         child: Padding(
           padding: const EdgeInsets.all(16),
           child: Text(t('loginDonor')),
         ),
       );
     }
     return Card(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       child: Padding(
         padding: const EdgeInsets.all(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               t('upcomingAppointments'),
               style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
             ),
             const SizedBox(height: 12),
             StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
               stream: _upcomingApptStream,
               builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                   return const Center(child: CircularProgressIndicator());
                 }
                 if (snapshot.hasError) {
                   return Text(t('errorOccurred'));
                 }
                 final docs = snapshot.data?.docs ?? [];
                 final now = DateTime.now();
                 final upcomingDocs = docs.where((doc) {
                   final data = doc.data();
                   final status = (data['status'] as String?) ?? 'upcoming';
                   if (status != 'upcoming') return false;
                   final dt = (data['date'] as Timestamp?)?.toDate();
                   if (dt == null) return true;
                   return !dt.isBefore(now);
                 }).toList();
                 if (upcomingDocs.isEmpty) {
                   return Text(t('noAppointments'));
                 }

                 return Column(
                   children: upcomingDocs.map((doc) {
                     final data = doc.data();
                     final dt = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                     final status = (data['status'] as String?) ?? 'upcoming';
                     final siteName = data['donationSiteName'] as String?;
                     final siteId = data['donationSiteId'] as String? ?? data['donationSiteID'] as String?;
                     final appointmentId = (data['appointmentID'] as String?) ?? doc.id;
                     final centerLabel = siteName?.isNotEmpty == true ? siteName! : t('donationSite');
                     return Container(
                       margin: const EdgeInsets.only(bottom: 12),
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: const Color(0xFFF5F5F5),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Container(
                                 width: 42,
                                 height: 42,
                                 decoration: BoxDecoration(
                                   color: const Color(0xFFFFEBEE),
                                   borderRadius: BorderRadius.circular(12),
                                 ),
                                 child: const Icon(Icons.event_available, color: Color(0xFFC62828)),
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       centerLabel,
                                       style: const TextStyle(fontWeight: FontWeight.w700),
                                     ),
                                     const SizedBox(height: 4),
                                     Text(
                                       _formatDateTime(dt),
                                       style: const TextStyle(color: Colors.black87),
                                     ),
                                     const SizedBox(height: 6),
                                     Text(
                                       status,
                                       style: const TextStyle(color: Colors.grey),
                                     ),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 12),
                           Row(
                             children: [
                               Expanded(
                                 child: OutlinedButton(
                                   onPressed: siteId == null
                                       ? null
                                       : () => _rescheduleAppointment(
                                             appointmentId: appointmentId,
                                             siteId: siteId,
                                             currentDate: dt,
                                           ),
                                   child: Text(t('reschedule')),
                                 ),
                               ),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: OutlinedButton(
                                   onPressed: siteId == null
                                       ? null
                                       : () => _cancelAppointment(
                                             appointmentId: appointmentId,
                                             siteId: siteId,
                                           ),
                                   style: OutlinedButton.styleFrom(
                                     foregroundColor: const Color(0xFFC62828),
                                     side: const BorderSide(color: Color(0xFFC62828)),
                                   ),
                                   child: Text(t('cancel')),
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     );
                   }).toList(),
                 );
               },
             ),
           ],
         ),
       ),
     ); 
  }

  Future<void> _rescheduleAppointment({
    required String appointmentId,
    required String siteId,
    required DateTime currentDate,
  }) async {
    final now = DateTime.now();
    final initialDate = currentDate.isBefore(now) ? now : currentDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDate),
    );
    if (pickedTime == null) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final uid = FirebaseAuth.instance.currentUser?.uid ?? Session.uid;
    if (uid == null) return;

    final ts = Timestamp.fromDate(newDateTime);
    final donorRef = FirebaseFirestore.instance
        .collection('donors')
        .doc(uid)
        .collection('donorappointments')
        .doc(appointmentId);
    final siteRef = FirebaseFirestore.instance
        .collection('donationsites')
        .doc(siteId)
        .collection('siteappointments')
        .doc(appointmentId);

    try {
      await Future.wait([
        donorRef.set({'date': ts, 'status': 'upcoming'}, SetOptions(merge: true)),
        siteRef.set({'date': ts, 'status': 'upcoming'}, SetOptions(merge: true)),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('reschedule'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('errorOccurred'))),
      );
    }
  }

  Future<void> _cancelAppointment({
    required String appointmentId,
    required String siteId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? Session.uid;
    if (uid == null) return;

    final donorRef = FirebaseFirestore.instance
        .collection('donors')
        .doc(uid)
        .collection('donorappointments')
        .doc(appointmentId);
    final siteRef = FirebaseFirestore.instance
        .collection('donationsites')
        .doc(siteId)
        .collection('siteappointments')
        .doc(appointmentId);

    try {
      await Future.wait([
        donorRef.set({'status': 'cancelled'}, SetOptions(merge: true)),
        siteRef.set({'status': 'cancelled'}, SetOptions(merge: true)),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('cancel'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('errorOccurred'))),
      );
    }
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _metricBlock({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _metricRow(icon: icon, label: label, value: value, color: color);
  }

  Widget _metricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _eligibilityStatus(EligibilityResult? eligibility) {
    Color bgColor;
    String text;
    if (eligibility == null) {
      bgColor = const Color(0xFFFFF3E0);
      text = t('readVitalsFirst');
    } else if (eligibility.ok) {
      bgColor = const Color(0xFFE8F5E9);
      text = t('donationSafe');
    } else {
      bgColor = const Color(0xFFFFEBEE);
      text = eligibility.reasonKey != null ? t(eligibility.reasonKey!) : t('donationUnsafe');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('readFromBracelet'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
} 
