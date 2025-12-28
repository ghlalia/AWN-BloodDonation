import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VitalsService {
  VitalsService._();
  static final instance = VitalsService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  
  Future<Map<String, dynamic>> generateAndSaveMockVitals() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    final rand = Random();

    // REALISTIC medical ranges
    final systolic = 100 + rand.nextInt(21);    // 100–120
    final diastolic = 70 + rand.nextInt(11);    // 70–80
    final oxygen = 96 + rand.nextInt(5);        // 96–100

    final data = {
      'systolic': systolic,
      'diastolic': diastolic,
      'oxygenlevel': oxygen,
      'timestamp': Timestamp.now(),
    };

    await _db
        .collection('donors')
        .doc(user.uid)
        .collection('vitals')
        .add(data);

    return data;
  }
}
