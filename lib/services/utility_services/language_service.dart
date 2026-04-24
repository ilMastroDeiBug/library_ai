import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String defaultLanguage = 'it-IT';

  String _currentLanguage = defaultLanguage;

  String get currentLanguage => _currentLanguage;

  // Ritorna 'it' o 'en' per le API che lo richiedono
  String get shortCode => _currentLanguage.split('-')[0];

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = _normalizeLanguage(
      prefs.getString('app_language'),
    );
    notifyListeners();
  }

  Future<void> updateLanguage(String newLang) async {
    final normalized = _normalizeLanguage(newLang);
    if (_currentLanguage == normalized) return;
    _currentLanguage = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', normalized);
    notifyListeners();
  }

  Future<void> syncLanguage(String? newLang, {bool notify = true}) async {
    final normalized = _normalizeLanguage(newLang);
    if (_currentLanguage == normalized) return;
    _currentLanguage = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', normalized);
    if (notify) {
      notifyListeners();
    }
  }

  String _normalizeLanguage(String? language) {
    switch (language) {
      case 'en':
      case 'en-US':
        return 'en-US';
      case 'it':
      case 'it-IT':
      default:
        return defaultLanguage;
    }
  }
}
