import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class PinScreen extends StatefulWidget {
  final bool isSetting;
  const PinScreen({super.key, required this.isSetting});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _error = '';

  void _handlePin() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      setState(() => _error = 'الرجاء إدخال 4 أرقام على الأقل');
      return;
    }

    if (widget.isSetting) {
      await AuthService.setPin(pin);
      if (mounted) Navigator.pop(context);
    } else {
      final isValid = await AuthService.verifyPin(pin);
      if (isValid) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        setState(() => _error = 'رمز PIN غير صحيح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isSetting ? 'إعداد PIN' : 'أدخل PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.indigo),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 10),
              decoration: const InputDecoration(
                hintText: '****',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handlePin,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: Text(widget.isSetting ? 'حفظ' : 'دخول'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
