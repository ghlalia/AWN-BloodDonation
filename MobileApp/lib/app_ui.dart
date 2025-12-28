import 'package:flutter/material.dart';
import '../main.dart';
import '../string.dart';
import '../core/session.dart';
import '../core/data_store.dart';
import '../core/auth_state.dart';
import '../Home/Home_screen.dart';
import '../search/search_screen.dart';
import '../auth/login_chooser.dart';
import '../account/account_screen.dart';

PreferredSizeWidget buildAwnAppBar(BuildContext context) => AppBar(
  elevation: 0,
  backgroundColor: Colors.white,
  titleSpacing: 0,
  leadingWidth: 120,
  leading: Padding(
    padding: const EdgeInsetsDirectional.only(start: 16),
    child: Image.asset('assets/images/logo.png', height: 50, fit: BoxFit.contain),
  ),
  actions: [
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'en') {
          await LocaleScope.of(context).setLocale(const Locale('en'));
        } else if (value == 'ar') {
          await LocaleScope.of(context).setLocale(const Locale('ar'));
        } else if (value == 'logout') {
          await AuthState.signOut();
          DataStore.I.clearSession();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Strings.t(context, 'loggedOut'))),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          PopupMenuItem(value: 'en', child: Text(Strings.t(context, 'english'))),
          PopupMenuItem(value: 'ar', child: Text(Strings.t(context, 'arabic'))),
        ];
        if (Session.isLoggedIn) {
          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem(value: 'logout', child: Text(Strings.t(context, 'logout'))));
        }
        return items;
      },
    ),
  ],
);

BottomNavigationBar buildBottomNav(BuildContext ctx, int current) {
  return BottomNavigationBar(
    currentIndex: current,
    selectedItemColor: const Color(0xFFC62828),
    unselectedItemColor: Colors.grey,
    onTap: (i) {
      if (i == current) return;
      if (i == 0) {
        Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const SearchScreen()));
      } else if (i == 1) {
        Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else if (i == 2) {
        if (Session.isLoggedIn && Session.accountRole != null) {
          Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => AccountScreen(role: Session.accountRole)));
        } else {
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const LoginChooserScreen(redirectToAccount: true)),
          );
        }
      }
    },
    items: [
      BottomNavigationBarItem(icon: const Icon(Icons.search), label: Strings.t(ctx, 'search')),
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: Strings.t(ctx, 'home')),
      BottomNavigationBarItem(icon: const Icon(Icons.person), label: Strings.t(ctx, 'account')),
    ],
  );
}
