import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_theme.dart';
import 'screens/wizard_screen.dart';

class OpcApp extends StatelessWidget {
  const OpcApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set default animation duration globally
    Animate.restartOnHotReload = true;

    return MaterialApp(
      title: 'OPC - Options Profit Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const WizardScreen(),
    );
  }
}
