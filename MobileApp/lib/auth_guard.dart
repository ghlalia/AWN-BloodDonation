import 'package:flutter/material.dart';
import 'session.dart';

class AuthGuard {
  static bool get isLoggedIn => Session.isLoggedIn;

  static Future<void> requireLogin(BuildContext context) async {
    if (!Session.isLoggedIn) {
      await Navigator.of(context).pushNamed('/loginChooser');
    }
  }
}
