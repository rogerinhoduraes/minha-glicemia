import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/analytics_service.dart';
import 'services/notificacao_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('pt_BR');
  await NotificacaoService.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const seed  = Color(0xFF2563EB);
    const ink   = Color(0xFF1A1E2E); // flat header — replaces cold navy gradient
    const stone = Color(0xFFF2EFE9); // warm background — replaces cold slate-100
    const warm0 = Color(0xFFFAFAF8); // warm card surface
    const warm1 = Color(0xFFE5E0D8); // warm border
    const warm2 = Color(0xFFF7F5F1); // warm input fill
    const warm3 = Color(0xFFEDE9E2); // warm divider
    const muted = Color(0xFF6B6860); // warm secondary text

    final base = ThemeData.light(useMaterial3: true);
    final cs = ColorScheme.fromSeed(seedColor: seed);
    final tt = GoogleFonts.nunitoSansTextTheme(base.textTheme);

    return MaterialApp(
      title: 'Minha Glicemia',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: base.copyWith(
        colorScheme: cs,
        textTheme: tt,
        scaffoldBackgroundColor: stone,
        cardTheme: CardThemeData(
          elevation: 0,
          color: warm0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: warm1),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: ink,
          titleTextStyle: GoogleFonts.nunitoSans(
            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: warm2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: warm1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: warm1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: seed, width: 2),
          ),
          labelStyle: TextStyle(color: muted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: seed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.nunitoSans(fontSize: 17, fontWeight: FontWeight.w800),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: warm0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: warm0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        dividerTheme: const DividerThemeData(color: warm3, thickness: 1),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: warm0,
          indicatorColor: seed.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.nunitoSans(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      navigatorObservers: [AnalyticsService.observer],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.data != null ? const MainScreen() : const LoginScreen();
        },
      ),
    );
  }
}
