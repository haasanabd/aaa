import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/pin_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pinEnabled = await AuthService.isPinEnabled();
  
  runApp(HaaBackupApp(startWithPin: pinEnabled));
}

class HaaBackupApp extends StatelessWidget {
  final bool startWithPin;

  const HaaBackupApp({super.key, required this.startWithPin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haa Backup',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: startWithPin ? const PinScreen(isSetting: false) : const HomeScreen(),
    );
  }
}
