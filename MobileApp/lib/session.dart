import 'models.dart';

class Session {
  static String? uid;
  static String? role;
  static bool isLoggedIn = false;
  static Map<String, dynamic>? profile;

  static AccountRole? accountRole;
  static String? siteCenterId;
  static String? siteContactNumber;

  static void clear() {
    uid = null;
    role = null;
    isLoggedIn = false;
    profile = null;
    accountRole = null;
    siteCenterId = null;
    siteContactNumber = null;
  }
}
