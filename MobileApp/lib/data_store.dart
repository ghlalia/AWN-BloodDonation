import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; 
import 'models.dart';
import '../core/ble_service.dart';


class DonationSite {
  final String docId; // Firestore document id
  final String siteId;
  final String siteName;
  final String email;
  final String contactNumber;
  final String location;

  DonationSite({
    required this.docId,
    required this.siteId,
    required this.siteName,
    required this.email,
    required this.contactNumber,
    required this.location,
  });

  factory DonationSite.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DonationSite(
      docId: doc.id,
      siteId: (data['siteID'] as String?) ?? (data['siteId'] as String?) ?? doc.id,
      siteName: data['SiteName'] as String? ?? data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      contactNumber: data['contactnumber'] as String? ?? data['contact'] as String? ?? '',
      location: data['location'] as String? ?? data['address'] as String? ?? '',
    );
  }
}

class DataStore {
  DataStore._();
  static final DataStore instance = DataStore._();
  static final DataStore I = instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Vitals? latestVitals;

  bool get isLoggedIn => _auth.currentUser != null;

  Future<void> signOut() async {
    await _auth.signOut();
    latestVitals = null;
  }

  //  AUTH
  Future<UserCredential> signUpDonor({
    required String name,
    required String email,
    required String password,
    required int age,
    required String phone,
    required String location,
    required String bloodType,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    await _db.collection('donors').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'password': '',
      'Phone': phone,
      'age': age,
      'location': location,
      'bloodtype': bloodType,
      'role': 'donor',
    });

    return cred;
  }

  Future<UserCredential> signUpSite({
    required String siteName,
    required String email,
    required String password,
    required String contactNumber,
    required String location,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    await _db.collection('donationsites').doc(uid).set({
      'siteID': uid,
      'SiteName': siteName,
      'email': email,
      'password': '',
      'contactnumber': contactNumber,
      'location': location,
      'role': 'donation site',
    });

    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final uid = user.uid;

    final donorDoc = await _db.collection('donors').doc(uid).get();
    if (donorDoc.exists) {
      final data = donorDoc.data()!..putIfAbsent('role', () => 'donor');
      return data;
    }

    final siteDoc = await _db.collection('donationsites').doc(uid).get();
    if (siteDoc.exists) {
      final data = siteDoc.data()!..putIfAbsent('role', () => 'donation site');
      return data;
    }

    return null;
  }


  Future<DonationSite?> getCurrentDonationSite() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('donationsites').doc(user.uid).get();
    if (!doc.exists) return null;
    return DonationSite.fromFirestore(doc);
  }

  //  FIRESTORE WRITES 
  Future<void> addDonorVitals({
    required String uid,
    required int systolic,
    required int diastolic,
    required int heartRate,
    required int oxygenLevel,
    DateTime? timestamp,
  }) async {
    final col = _db.collection('donors').doc(uid).collection('vitals');
    final docRef = col.doc();
    final data = <String, dynamic>{
      'systolic': systolic,
      'diastolic': diastolic,
      'heartrate': heartRate,
      'oxygenlevel': oxygenLevel,
      'timestamp':
          timestamp != null ? Timestamp.fromDate(timestamp) : FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
  }

  Future<void> saveHeartRateForCurrentUser(int hr) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db
        .collection('donors')
        .doc(user.uid)
        .collection('vitals')
        .add({
      'heartrate': hr,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> addDonorAppointment({
    required String uid,
    required DateTime date,
    required String status,
  }) async {
    final col =
        _db.collection('donors').doc(uid).collection('donorappointments');
    final docRef = col.doc();
    await docRef.set({
      'appointmentID': docRef.id,
      'date': Timestamp.fromDate(date),
      'status': status,
    });
    return docRef;
  }

  Future<void> addSiteAppointment({
    required String siteId,
    required DateTime date,
    required String donorId,
    required String donorName,
    required String donorBloodType,
    required String status,
    String? appointmentId,
  }) async {
    final col = _db
        .collection('donationsites')
        .doc(siteId)
        .collection('siteappointments');
    final docRef = col.doc();
    await docRef.set({
      'appointmentID': appointmentId ?? docRef.id,
      'date': Timestamp.fromDate(date),
      'donorBloodType': donorBloodType,
      'donorid': donorId,
      'donorname': donorName,
      'status': status,
    });
  }

  Future<void> createDonationSite({
    required String siteId,
    required String email,
    required String name,
    required String address,
    required String contactNumber,
    required double latitude,
    required double longitude,
  }) async {
    await _db.collection('donationsites').doc(siteId).set({
      'siteId': siteId,
      'siteID': siteId, 
      'email': email,
      'name': name,
      'SiteName': name, 
      'address': address,
      'location': address,
      'contact': contactNumber,
      'contactnumber': contactNumber,
      'lat': latitude,
      'lng': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateInventory({
    required String siteId,
    required String bloodType,
    required int units,
  }) async {
    await _db
        .collection('donationsites')
        .doc(siteId)
        .collection('inventory')
        .doc(bloodType)
        .set({
      'bloodType': bloodType,
      'units': units,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // live inventory stream
  Stream<List<Map<String, dynamic>>> watchInventory(String siteId) {
    return _db
        .collection('donationsites')
        .doc(siteId)
        .collection('inventory')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // Needed blood types based on inventory units threshold
  Stream<List<String>> watchNeededBloodTypes(String siteId, {int shortageThreshold = 3}) {
    return watchInventory(siteId).map((list) {
      final needed = <String>[];
      for (final item in list) {
        final blood = item['bloodType'] as String? ?? '';
        final units = (item['units'] as num?)?.toInt() ?? 0;
        // treat 0 units as shortage even if threshold logic changes
        if (blood.isNotEmpty && (units <= shortageThreshold || units == 0)) {
          needed.add(blood);
        }
      }
      needed.sort();
      debugPrint('Needed types for $siteId: ${needed.join(', ')}');
      return needed;
    });
  }

  // writes appointment for donor and donation site atomically
  Future<void> bookAppointment({
    required String donorId,
    required String donorName,
    required String donorBloodType,
    required String siteId,
    required String siteName,
    required DateTime dateTime,
  }) async {
    final appointmentId = _db.collection('dummy').doc().id;
    final donorAppointmentRef =
        _db.collection('donors').doc(donorId).collection('donorappointments').doc(appointmentId);
    final siteAppointmentRef = _db
        .collection('donationsites')
        .doc(siteId)
        .collection('siteappointments')
        .doc(appointmentId);

    final ts = Timestamp.fromDate(dateTime);
    final batch = _db.batch();

    // donor record
    batch.set(donorAppointmentRef, {
      'appointmentID': appointmentId,
      'date': ts,
      'status': 'upcoming',
      
      'donationSiteId': siteId,
      'donationSiteName': siteName,
      'donorId': donorId,
      'donorName': donorName,
      'donorBloodType': donorBloodType,
    });

    // site record
    batch.set(siteAppointmentRef, {
      'date': ts,
      'donorBloodType': donorBloodType,
      'donorid': donorId,
      'donorname': donorName,
      'status': 'upcoming',
    });

    await batch.commit();
  }

  

  // ELIGIBILITY 
  EligibilityResult checkEligibility({required int age, required Vitals vitals}) {
    if (age < 18) return const EligibilityResult.fail('eligibility_age');
    if (vitals.systolic < 90 || vitals.systolic > 140) {
      return const EligibilityResult.fail('eligibility_bp');
    }
    if (vitals.pulse < 50 || vitals.pulse > 110) {
      return const EligibilityResult.fail('eligibility_pulse');
    }
    return const EligibilityResult.ok();
  }

  Future<Vitals> readVitalsFromBracelet() async {
  
    final systolic = await readSystolic() ?? 120; // Default if 0
    final diastolic = await readDiastolic() ?? 80; // Default if 0

    final heartRate = await readHeartRateFromHardware();
    final oxygen = await readOxygenFromHardware();
     
     if (!BleService.I.isConnected) {
      BleService.I.connect();
    }

    if (heartRate == null || oxygen == null ) {
      throw Exception('Failed to read heart rate or oxygen from bracelet');
    }

    latestVitals = Vitals(
      systolic: systolic,
      diastolic: diastolic ,
      pulse: heartRate,
      
      oxygenLevel: oxygen, 
      heartRate: heartRate, 
    );
    return latestVitals!;
  }

  // hardware reading
  Future<int?> readOxygenFromHardware() async {
    return await BleService.I.readOxygen();
  }

  Future<int?> readHeartRateFromHardware() async {
    return await BleService.I.readHeartRate();
  }

  Future<int?> readSystolic() async {
    return await BleService.I.readSystolic();
  }
  
  Future<int?> readDiastolic() async {
    return await BleService.I.readDiastolic();
  }


  void clearSession() {
    latestVitals = null;
  }

  List<String> shortages(String centerId) {
    return const [];
  }
}
