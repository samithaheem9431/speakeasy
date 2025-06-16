import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speakeasy/screens/splash_screen.dart';
import 'onboarding_page.dart';
import 'loading_screen.dart';

Future<void> backgroundmessage(RemoteMessage message) async{

}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(backgroundmessage);
  await MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<Widget> _getStartScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('seenOnboard') ?? false;

    if (seen) {
      return SplashScreen();
    } else {
      await prefs.setBool('seenOnboard', true);
      return OnboardingPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2E3F7F),
          secondary: Color(0xFF41C3E5),
          tertiary: Color(0xFFF27649),
          surface: Colors.white,
          background: Color(0xFFF8F9FC),
          onPrimary: Colors.white,
        ),
        primaryColor: Color(0xFF2E3F7F),
        scaffoldBackgroundColor: Color(0xFFF8F9FC),
        fontFamily: GoogleFonts.poppins().fontFamily,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF2E3F7F),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: Color(0xFF2E3F7F)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2E3F7F),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E3F7F)),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF2E3F7F)),
          bodyLarge: TextStyle(fontSize: 18, color: Color(0xFF404B69), height: 1.5),
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF404B69), height: 1.5),
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _getStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.data!;
          } else {
            return LoadingScreen();
          }
        },
      ),
    );
  }
}