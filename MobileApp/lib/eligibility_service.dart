import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EligibilityService {
  EligibilityService._();
  static final instance = EligibilityService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Returns true if donor is eligible for donation.
  /// Conditions:
  /// - Age >= 18
  /// - systolic between 100–120
  /// - diastolic between 70–80
  /// - oxygenlevel between 96–100
  Future<bool> isDonorEligible(Map<String, dynamic> vitals) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final donorDoc =
        await _db.collection('donors').doc(user.uid).get();

    if (!donorDoc.exists) return false;

    final data = donorDoc.data()!;
    final age = data['age'] ?? 0;

    if (age < 18) return false;

    final systolic = vitals['systolic'];
    final diastolic = vitals['diastolic'];
    final oxygen = vitals['oxygenlevel'];
    final HeartRate = vitals ['HeartRate'];

    final bool systolicOk = systolic >= 100 && systolic <= 120;
    final bool diastolicOk = diastolic >= 70 && diastolic <= 80;
    final bool oxygenOk = oxygen >= 96 && oxygen <= 100;
    final bool HeartRateOk = HeartRate >= 60 && HeartRate <= 100;

    return systolicOk && diastolicOk && oxygenOk && HeartRateOk;
  }
}
