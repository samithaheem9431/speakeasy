import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speakeasy/screens/phrasebook_screen.dart';
import 'package:speakeasy/screens/translator_controller.dart';
import 'package:speakeasy/screens/translator_ui.dart';
import '../firebase_notification_service.dart';
import '../signin_page.dart';
import 'translation_history.dart';

class VoiceTranslatorApp extends StatefulWidget {
  @override
  State<VoiceTranslatorApp> createState() => _VoiceTranslatorAppState();
}

class _VoiceTranslatorAppState extends State<VoiceTranslatorApp> {
  final controller = TranslatorController();

  @override
  void initState() {
    super.initState();
    controller.initialize(context, setState);
    FirebaseNotificationService.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = controller.isDarkMode ? const Color(0xFF26A69A) : const Color(0xFF00695C);
    final bgColor = controller.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = controller.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final accentColor = controller.isDarkMode ? const Color(0xFF4DB6AC) : const Color(0xFF26A69A);

    return Theme(
      data: controller.isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: bgColor,
        cardColor: cardColor,
        appBarTheme: AppBarTheme(
          backgroundColor: cardColor,
          elevation: 0,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      )
          : ThemeData.light().copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: bgColor,
        cardColor: cardColor,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          elevation: 0,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.translate, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Voice Translator"),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(controller.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => controller.toggleTheme(context, setState),

              tooltip: controller.isDarkMode ? "Light Mode" : "Dark Mode",
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: controller.isDarkMode
                  ? [bgColor, const Color(0xFF1A1A1A)]
                  : [bgColor, const Color(0xFFE8F5E8)],
            ),
          ),
          child: controller.buildTranslatorBody(context, primaryColor, setState),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: controller.selectedIndex,
            backgroundColor: controller.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            selectedItemColor: controller.isDarkMode ? Colors.white : const Color(0xFF00695C),
            unselectedItemColor: controller.isDarkMode ? Colors.grey[500] : Colors.grey[600],
            type: BottomNavigationBarType.fixed, // Ensures all icons and labels show
            onTap: (index) async {
              if (index == 3) {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SignInPage()));
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TranslationHistoryScreen(
                      history: controller.translationHistory,
                      onClear: () => controller.clearHistory(setState),
                      isDarkMode: controller.isDarkMode,
                    ),
                  ),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhrasebookScreen(controller: controller),
                  ),
                );
              } else {
                setState(() => controller.selectedIndex = index);
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "History"),
              BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: "Phrasebook"),
              BottomNavigationBarItem(icon: Icon(Icons.logout_rounded), label: "Logout"),

            ],
          ),
        ),
      ),
    );
  }
}