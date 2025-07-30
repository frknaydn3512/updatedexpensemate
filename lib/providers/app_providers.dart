import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tema modu enum'ı
enum ThemeModeOption {
  system, // Sistem temasına göre
  light,  // Açık tema
  dark,   // Koyu tema
}

class ThemeProvider with ChangeNotifier {
  // Mevcut tema modunu tutan değişken
  ThemeModeOption _themeMode = ThemeModeOption.system;
  ThemeModeOption get themeMode => _themeMode;

  // Constructor: Tema tercihini yükler
  ThemeProvider() {
    _loadThemeMode();
  }

  // Tema modunu değiştirme metodu
  void setThemeMode(ThemeModeOption mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveThemeMode(mode); // Tercihi kaydet
      notifyListeners(); // Tema değiştiğini dinleyicilere bildir
    }
  }

  // Kaydedilmiş tema tercihini yükle
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedMode = prefs.getString('themeMode');

    if (savedMode != null) {
      _themeMode = ThemeModeOption.values.firstWhere(
        (e) => e.toString() == 'ThemeModeOption.$savedMode',
        orElse: () => ThemeModeOption.system, // Bulamazsa varsayılanı sistem yap
      );
    }
    // Yükleme tamamlandığında dinleyicileri bildirmeye gerek yok
    // çünkü constructor'da çağrılıyor ve henüz widget'lar dinlemiyor olabilir.
    // Ancak, eğer sonradan çağrılıyorsa notifyListeners() gerekebilir.
  }

  // Tema tercihini kaydet
  Future<void> _saveThemeMode(ThemeModeOption mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name); // enum adını kaydet
  }

  // Uygulamanın gerçekten hangi tema modunda çalışması gerektiğini döndürür.
  // Bu metod, MaterialApp'in themeMode özelliği için kullanılır.
  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case ThemeModeOption.system:
        return ThemeMode.system;
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
    }
  }
}

class LanguageProvider extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
} 