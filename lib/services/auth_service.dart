import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'user_pin_v2';
  static const _saltKey = 'user_salt';
  static const _pinEnabledKey = 'pin_enabled';

  static Future<bool> isPinEnabled() async {
    try {
      final enabled = await _storage.read(key: _pinEnabledKey);
      return enabled == 'true';
    } catch (e) {
      debugPrint('Error checking PIN status: $e');
      return false;
    }
  }

  static Future<void> setPin(String pin) async {
    try {
      // توليد Salt عشوائي
      final salt = _generateSalt();
      
      // تشفير الـ PIN مع الـ Salt باستخدام Isolate لمنع تجمد الواجهة
      final hashedPin = await compute(_hashPinWithSalt, {'pin': pin, 'salt': salt});
      
      await _storage.write(key: _saltKey, value: salt);
      await _storage.write(key: _pinKey, value: hashedPin);
      await _storage.write(key: _pinEnabledKey, value: 'true');
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      rethrow;
    }
  }

  static Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinKey);
      final salt = await _storage.read(key: _saltKey);
      
      if (storedHash == null || salt == null) return false;
      
      final currentHash = await compute(_hashPinWithSalt, {'pin': pin, 'salt': salt});
      return storedHash == currentHash;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  static Future<void> disablePin() async {
    try {
      await _storage.write(key: _pinEnabledKey, value: 'false');
      await _storage.delete(key: _pinKey);
      await _storage.delete(key: _saltKey);
    } catch (e) {
      debugPrint('Error disabling PIN: $e');
    }
  }

  static String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  // دالة التشفير (تعمل في Isolate منفصل)
  static String _hashPinWithSalt(Map<String, String> data) {
    final pin = data['pin']!;
    final salt = data['salt']!;
    
    // استخدام PBKDF2-like approach بسيط عبر تكرار التشفير لزيادة الصعوبة
    var bytes = utf8.encode(pin + salt);
    var digest = sha256.convert(bytes);
    
    // تكرار التشفير 1000 مرة لزيادة الأمان ضد هجمات Brute Force
    for (int i = 0; i < 1000; i++) {
      digest = sha256.convert(digest.bytes + bytes);
    }
    
    return digest.toString();
  }
}
