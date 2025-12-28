import 'package:flutter/material.dart';
import '../string.dart';
import '../ui/app_nav.dart' as nav;
import '../ui/app_ui.dart' as ui;
import '../core/session.dart';
import '../core/models.dart';
import 'user_account_screen.dart';
import 'site_account_screen.dart';

class AccountScreen extends StatelessWidget {
  final AccountRole? role;
  const AccountScreen({super.key, this.role});

  AccountRole? get _resolvedRole => role ?? Session.accountRole;

  @override
  Widget build(BuildContext context) {
    final resolvedRole = _resolvedRole;
    final Widget content =
        (resolvedRole == AccountRole.site) ? const SiteAccountScreen() : const UserAccountScreen();

    return Directionality(
      textDirection: Strings.dir(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: ui.buildAwnAppBar(context),
        body: SafeArea(
          top: false,
          child: content,
        ),
        bottomNavigationBar: nav.buildBottomNav(context, 2),
      ),
    );
  }
}
