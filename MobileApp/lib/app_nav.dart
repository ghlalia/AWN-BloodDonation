import 'package:flutter/material.dart';
import '../string.dart';
import '../core/session.dart';


import '../Home/Home_screen.dart';
import '../search/search_screen.dart';
import '../auth/login_chooser.dart';
import '../account/account_screen.dart';

BottomNavigationBar buildBottomNav(BuildContext ctx, int currentIndex) {
  return BottomNavigationBar(
    currentIndex: currentIndex, // 0 = Search, 1 = Home, 2 = Account
    selectedItemColor: const Color(0xFFC62828), 
    unselectedItemColor: Colors.grey,
    onTap: (i) async {
      if (i == currentIndex) return; 

      if (i == 0) {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
      } else if (i == 1) {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (i == 2) {
        final role = Session.accountRole;
        if (Session.isLoggedIn && role != null) {
          Navigator.pushReplacement(
            ctx,
            MaterialPageRoute(
              builder: (_) => AccountScreen(role: role),
            ),
          );
        } else {
          await Navigator.push<bool>(
            ctx,
            MaterialPageRoute(builder: (_) => const LoginChooserScreen(redirectToAccount: true)),
          );
        }
      }
    },
    items: [
      BottomNavigationBarItem(
        icon: const Icon(Icons.search),
        label: Strings.t(ctx, 'search'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.home),
        label: Strings.t(ctx, 'home'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person),
        label: Strings.t(ctx, 'account'),
      ),
    ],
  );
}
