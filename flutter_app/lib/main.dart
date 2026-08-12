import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cards_provider.dart';
import 'providers/notification_provider.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/cards_list_screen.dart';
import 'screens/card_detail_screen.dart';
import 'screens/create_card_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/activity_log_screen.dart';
import 'screens/qr_scanner_screen.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CardsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const RouteCardApp(),
    ),
  );
}

class RouteCardApp extends StatelessWidget {
  const RouteCardApp({super.key});

  // ASM Brand Colors
  static const Color asmNavy = Color(0xFF082B63);
  static const Color asmBlue = Color(0xFF0B3F8A);
  static const Color asmElectric = Color(0xFF3B82F6);
  static const Color asmSurface = Color(0xFF0F172A);
  static const Color asmCard = Color(0xFF1E293B);
  static const Color asmAccent = Color(0xFF06B6D4);
  static const Color asmGreen = Color(0xFF10B981);
  static const Color asmRed = Color(0xFFEF4444);
  static const Color asmOrange = Color(0xFFF59E0B);
  static const Color asmPurple = Color(0xFF8B5CF6);
  static const Color asmTextPrimary = Color(0xFFF8FAFC);
  static const Color asmTextSecondary = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Light Theme Colors
    const Color lightSurface = Color(0xFFF8FAFC);
    const Color lightCard = Color(0xFFFFFFFF);
    const Color lightTextPrimary = Color(0xFF0F172A);
    const Color lightTextSecondary = Color(0xFF64748B);

    return MaterialApp(
      title: 'ASM Production Management System',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      
      // LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: asmNavy,
        scaffoldBackgroundColor: lightSurface,
        colorScheme: const ColorScheme.light(
          primary: asmElectric,
          secondary: asmAccent,
          surface: lightCard,
          error: asmRed,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: asmNavy,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: lightCard,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: asmElectric,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: asmElectric, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: asmElectric,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),

      // DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: asmNavy,
        scaffoldBackgroundColor: asmSurface,
        colorScheme: const ColorScheme.dark(
          primary: asmElectric,
          secondary: asmAccent,
          surface: asmCard,
          error: asmRed,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: asmNavy,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: asmTextPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: asmCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: asmElectric,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: asmSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: asmElectric, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: asmElectric,
          foregroundColor: Colors.white,
          elevation: 8,
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const DashboardScreen() : const LoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/cards': (_) => const CardsListScreen(),
        '/create-card': (_) => const CreateCardScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/activity-log': (_) => const ActivityLogScreen(),
        '/qr-scan': (_) => const QRScannerScreen(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        if (uri.path == '/card-detail') {
          final cardId = uri.queryParameters['id'] ?? settings.arguments as String?;
          if (cardId != null) {
            return MaterialPageRoute(
              builder: (_) => CardDetailScreen(cardId: cardId),
            );
          }
        }
        return null;
      },
    );
  }
}
