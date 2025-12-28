import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _map;
  AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    _AppLocalizationsDelegate(),
  ];

  Future<void> load() async {
    final path = 'assets/i18n/${locale.languageCode}.json';
    final jsonStr = await rootBundle.loadString(path);
    _map = (json.decode(jsonStr) as Map).map((k, v) => MapEntry(k, v.toString()));
  }

  String t(String key) => _map[key] ?? key;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final l = AppLocalizations(locale);
    await l.load();
    return l;
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
