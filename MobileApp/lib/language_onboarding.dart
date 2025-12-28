import 'package:flutter/material.dart';

class LanguageOnboarding extends StatelessWidget {
  const LanguageOnboarding({
    super.key,
    required this.onLanguageSelected,
  });

  final Future<void> Function(Locale) onLanguageSelected;

  static const Color awnRed = Color(0xFFC62828);
  static const Color textDark = Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView( 
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                ),
                const SizedBox(height: 24),

                const Text(
                  'Welcome to Awn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: awnRed,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Start your journey of giving',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 64),

                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await onLanguageSelected(const Locale('en'));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: awnRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('English'),
                          
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await onLanguageSelected(const Locale('ar'));
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: awnRed, width: 1.4),
                            foregroundColor: awnRed,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('العربية'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

               
              ],
            ),
          ),
        ),
      ),
    );
  }
}
