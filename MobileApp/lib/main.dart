// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_theme.dart';
import 'Home/Home_screen.dart';
import 'onboarding/language_onboarding.dart';
import 'auth/login_chooser.dart';
import 'account/account_screen.dart';
import 'core/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Request Bluetooth/location permissions up front for BLE reads
  await Permission.location.request();
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  runApp(const AwnApp(showOnboarding: true));
}

class AwnApp extends StatefulWidget {
  const AwnApp({super.key, this.showOnboarding = true});
  final bool showOnboarding;

  @override
  State<AwnApp> createState() => _AwnAppState();
}

class _AwnAppState extends State<AwnApp> {

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  Locale? _locale;

  
  Future<void> setLocale(Locale locale) async {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      setLocale: setLocale,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),

        navigatorKey: _navigatorKey,

       
        locale: _locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        routes: {
          '/home': (_) => const HomeScreen(),
          '/loginChooser': (_) => const LoginChooserScreen(),
          '/appNav': (_) => const HomeScreen(),
          '/account': (_) => AccountScreen(role: Session.accountRole),
        },

       
        home: widget.showOnboarding
            ? LanguageOnboarding(
                onLanguageSelected: (locale) async {
                  await setLocale(locale);
           
                  _navigatorKey.currentState!.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              )
            : const HomeScreen(),
      ),
    );
  }
}


class LocaleScope extends InheritedWidget {
  final Future<void> Function(Locale) setLocale;
  const LocaleScope({super.key, required this.setLocale, required super.child});

  static LocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope is missing in the widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant LocaleScope oldWidget) =>
      oldWidget.setLocale != setLocale;
}
