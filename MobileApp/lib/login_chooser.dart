import 'package:flutter/material.dart';
import '../string.dart';
import '../core/session.dart';
import '../account/account_screen.dart';
import 'login_individual.dart';
import 'login_site.dart';
import 'signup_individual.dart';
import 'signup_site.dart';

class LoginChooserScreen extends StatelessWidget {
  const LoginChooserScreen({super.key, this.redirectToAccount = false});

  final bool redirectToAccount;

  String t(BuildContext c, String k) => Strings.t(c, k);

  void _handleSuccess(BuildContext context) {
    if (redirectToAccount && Session.isLoggedIn && Session.accountRole != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AccountScreen(role: Session.accountRole)),
        (route) => false,
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'login'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 96,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t(context, 'loginSubtitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginIndividualScreen()),
                  );
                  if (ok == true && context.mounted) _handleSuccess(context);
                },
                child: Text(t(context, 'logInAsDonor')),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginSiteScreen()),
                  );
                  if (ok == true && context.mounted) _handleSuccess(context);
                },
                child: Text(t(context, 'logInAsSite')),
              ),
              const SizedBox(height: 32),
              Center(child: Text(t(context, 'orSignUp'))),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpIndividualScreen()),
                  );
                  if (ok == true && context.mounted) _handleSuccess(context);
                },
                child: Text(t(context, 'signUpDonor')),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpSiteScreen()),
                  );
                  if (ok == true && context.mounted) _handleSuccess(context);
                },
                child: Text(t(context, 'signUpSite')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
