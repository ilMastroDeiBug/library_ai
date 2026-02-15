import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  String _currentLanguage = 'it-IT';

  String get currentLanguage => _currentLanguage;

  // Ritorna 'it' o 'en' per le API che lo richiedono
  String get shortCode => _currentLanguage.split('-')[0];

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'it-IT';
    notifyListeners();
  }

  Future<void> updateLanguage(String newLang) async {
    if (_currentLanguage == newLang) return;
    _currentLanguage = newLang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', newLang);
    notifyListeners();
  }
}
