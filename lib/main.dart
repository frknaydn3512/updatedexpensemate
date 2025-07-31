import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/database/app_database.dart';
import 'providers/app_providers.dart';
import 'services/notification_service.dart'; // Yeni ekledik
import 'ui/home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'ui/little_things/pin_lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bildirim servisini başlat
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Uygulama veritabanı ve sağlayıcıları
  final database = AppDatabase();
  final themeProvider = ThemeProvider();
  final languageProvider = LanguageProvider();

  // Günlük hatırlatıcıyı sadece bir kez ayarla
  final prefs = await SharedPreferences.getInstance();
  final isScheduled = prefs.getBool('daily_notification_scheduled') ?? false;
  if (!isScheduled) {
    try {
      await notificationService.scheduleDailyNotification(
        id: 100,
        title: 'Günlük Harcama Hatırlatıcısı',
        body: 'Bugünkü harcamalarınızı kaydettiniz mi?',
        time: const TimeOfDay(hour: 20, minute: 0),
      );
      await prefs.setBool('daily_notification_scheduled', true);
    } catch (e) {
      debugPrint('Failed to schedule daily notification: $e');
      // Continue app startup even if notification scheduling fails
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        Provider<AppDatabase>.value(value: database),
        Provider<NotificationService>.value(value: notificationService), // Yeni ekledik
      ],
      child: const ExpenseMateApp(),
    ),
  );
}

class ExpenseMateApp extends StatelessWidget {
  const ExpenseMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExpenseMate 2',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: languageProvider.locale,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeProvider.materialThemeMode,
      home: const PinLockOrHomePage(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1), // Modern indigo
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1), // Light theme ile aynı seed color
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937), // Modern dark blue
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF374151), // Modern dark gray
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF6366F1), // Light theme ile aynı
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1), // Light theme ile aynı
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF4B5563), // Dark input background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF6B7280)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      scaffoldBackgroundColor: const Color(0xFF111827), // Modern dark background
      dividerColor: const Color(0xFF374151), // Subtle dividers
      iconTheme: const IconThemeData(
        color: Color(0xFF9CA3AF), // Subtle icon color
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFF9FAFB)), // Light text on dark
        bodyMedium: TextStyle(color: Color(0xFFD1D5DB)), // Medium text
        bodySmall: TextStyle(color: Color(0xFF9CA3AF)), // Subtle text
      ),
    );
  }
}

class PinLockOrHomePage extends StatefulWidget {
  const PinLockOrHomePage({super.key});

  @override
  State<PinLockOrHomePage> createState() => _PinLockOrHomePageState();
}

class _PinLockOrHomePageState extends State<PinLockOrHomePage> {
  String? _savedPin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPin = prefs.getString('user_pin');
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _savedPin == null 
        ? const HomePage()
        : PinLockScreen(
            savedPin: _savedPin!,
            onSuccess: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            ),
          );
  }
}