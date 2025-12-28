import 'package:firebase_auth/firebase_auth.dart';
import 'session.dart';
import 'models.dart';

class AuthState {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<void> refreshSessionRole({
    required String role,
    required Map<String, dynamic> profile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      Session.clear();
      return;
    }
    Session.uid = user.uid;
    Session.role = role;
    Session.isLoggedIn = true;
    Session.profile = profile;
    Session.accountRole =
        role == 'donation site' ? AccountRole.site : AccountRole.individual;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    Session.clear();
  }
}
