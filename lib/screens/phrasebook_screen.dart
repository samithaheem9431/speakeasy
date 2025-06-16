import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'VoiceTranslatorApp.dart';
import 'translator_controller.dart';
import 'translation_history.dart';
import '../signin_page.dart';

class Phrase {
  final String englishText;
  String translatedText;
  bool isFavorite;

  Phrase({

    
    required this.englishText,
    this.translatedText = '',
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'englishText': englishText,
    'translatedText': translatedText,
    'isFavorite': isFavorite,
  };

  factory Phrase.fromJson(Map<String, dynamic> json) => Phrase(
    englishText: json['englishText'],
    translatedText: json['translatedText'],
    isFavorite: json['isFavorite'] ?? false,
  );
}

class PhrasebookScreen extends StatefulWidget {
  final TranslatorController controller;

  const PhrasebookScreen({super.key, required this.controller});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  final FlutterTts tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool isLoading = false;
  String selectedLanguageCode = '';
  String searchQuery = '';
  int _selectedIndex = 2;

  final Map<String, List<Phrase>> phrasebook = {
    'Greetings': [
      Phrase(englishText: 'Hello'),
      Phrase(englishText: 'Good morning'),
      Phrase(englishText: 'How are you?'),
      Phrase(englishText: 'Goodbye'),
    ],
    'Travel': [
      Phrase(englishText: 'Where is the hotel?'),
      Phrase(englishText: 'How much is this?'),
      Phrase(englishText: 'I need a taxi.'),
    ],
    'Emergency': [
      Phrase(englishText: 'Call the police'),
      Phrase(englishText: 'I need a doctor'),
      Phrase(englishText: 'Help me!'),
    ],
    'Dining': [
      Phrase(englishText: 'I am allergic to nuts'),
      Phrase(englishText: 'Can I see the menu?'),
      Phrase(englishText: 'The food is delicious'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences().then((_) {
      _loadCachedTranslations().then((_) => _translateAllPhrases());
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLang = prefs.getString('selectedLanguageCode');

    if (storedLang != null &&
        widget.controller.languageCodes.containsValue(storedLang)) {
      selectedLanguageCode = storedLang;
    } else {
      selectedLanguageCode = widget.controller.outputLangCode;
    }

    widget.controller.isDarkMode =
        prefs.getBool('isDarkMode') ?? widget.controller.isDarkMode;

    setState(() {});
  }

  Future<void> _speak(String text) async {
    try {
      await tts.setLanguage(selectedLanguageCode);
      await tts.speak(text);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Text-to-speech failed'),
          backgroundColor:
          widget.controller.isDarkMode ? const Color(0xFF1E1E1E) : Colors.red,
        ),
      );
    }
  }

  Future<String> _translate(String input) async {
    return await widget.controller
        .translateText(input, 'en', selectedLanguageCode, context);
  }

  Future<void> _translateAllPhrases() async {
    setState(() => isLoading = true);
    for (final category in phrasebook.values) {
      for (final phrase in category) {
        if (phrase.translatedText.isEmpty) {
          phrase.translatedText = await _translate(phrase.englishText);
        }
      }
    }
    await _saveCachedTranslations();
    setState(() => isLoading = false);
  }

  String _getCacheKey() => 'phrasebook_${selectedLanguageCode}_cache';

  Future<void> _saveCachedTranslations() async {
    final prefs = await SharedPreferences.getInstance();
    final allPhrases = phrasebook.entries.expand((e) => e.value).toList();
    final data = allPhrases.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_getCacheKey(), data);
  }

  Future<void> _loadCachedTranslations() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(_getCacheKey());
    if (cached == null) return;

    final allPhrases = phrasebook.entries.expand((e) => e.value).toList();
    for (int i = 0; i < allPhrases.length && i < cached.length; i++) {
      final decodedPhrase = Phrase.fromJson(jsonDecode(cached[i]));
      allPhrases[i]
        ..translatedText = decodedPhrase.translatedText
        ..isFavorite = decodedPhrase.isFavorite;
    }

    setState(() {});
  }

  Future<void> _clearCachedTranslations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getCacheKey());
    for (final category in phrasebook.values) {
      for (final phrase in category) {
        phrase.translatedText = '';
        phrase.isFavorite = false;
      }
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Cache cleared"),
        backgroundColor:
        widget.controller.isDarkMode ? const Color(0xFF4DB6AC) : const Color(0xFF26A69A),
      ),
    );
  }

  Future<void> _practicePhrase(Phrase phrase) async {
    final available = await _speech.initialize();
    if (!available) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Speech Recognition Error'),
          content: const Text('Speech recognition is not available.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            )
          ],
        ),
      );
      return;
    }

    await _speech.listen(
      localeId: widget.controller.getLocaleId(selectedLanguageCode),
      listenFor: const Duration(seconds: 5),
      onResult: (result) {
        _speech.stop();
        final spoken = result.recognizedWords.toLowerCase();
        final target = phrase.translatedText.toLowerCase();

        final match = spoken.contains(target) || target.contains(spoken);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              match ? '✅ Great job! You said it correctly.' : '❌ Not quite. Try again!',
            ),
            backgroundColor: match ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }

  Widget _buildLanguageDropdown() {
    final primaryColor =
    widget.controller.isDarkMode ? const Color(0xFF26A69A) : const Color(0xFF00695C);
    final cardColor =
    widget.controller.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final dropdownItems = widget.controller.languageCodes.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.value,
        child: Text(
          entry.key,
          style: TextStyle(
              color: widget.controller.isDarkMode ? Colors.white : Colors.black87),
        ),
      );
    }).toList();

    final validValue = dropdownItems.any((item) => item.value == selectedLanguageCode)
        ? selectedLanguageCode
        : widget.controller.outputLangCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: validValue,
        underline: const SizedBox(),
        dropdownColor: cardColor,
        onChanged: (value) async {
          if (value == null || value == selectedLanguageCode) return;

          setState(() {
            selectedLanguageCode = value;
            for (final cat in phrasebook.values) {
              for (final p in cat) {
                p.translatedText = '';
              }
            }
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('selectedLanguageCode', selectedLanguageCode);

          await _loadCachedTranslations();
          await _translateAllPhrases();
        },
        items: dropdownItems,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Greetings':
        return Icons.waving_hand;
      case 'Travel':
        return Icons.flight_takeoff;
      case 'Emergency':
        return Icons.emergency;
      case 'Dining':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VoiceTranslatorApp()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TranslationHistoryScreen(
            history: widget.controller.translationHistory,
            onClear: () => widget.controller.clearHistory(() {} as void Function(VoidCallback fn)),
            isDarkMode: widget.controller.isDarkMode,
          ),
        ),
      );
    } else if (index == 3) {
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SignInPage()),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.controller.isDarkMode ? const Color(0xFF26A69A) : const Color(0xFF00695C);
    final bgColor = widget.controller.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = widget.controller.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final accentColor = widget.controller.isDarkMode ? const Color(0xFF4DB6AC) : const Color(0xFF26A69A);
    final textColor = widget.controller.isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = widget.controller.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Theme(
      data: widget.controller.isDarkMode
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
                child: const Icon(Icons.menu_book_rounded, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Phrasebook"),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Clear Cache',
                onPressed: _clearCachedTranslations,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Translate Missing',
                onPressed: isLoading ? null : _translateAllPhrases,
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.controller.isDarkMode
                  ? [bgColor, const Color(0xFF1A1A1A)]
                  : [bgColor, const Color(0xFFE8F5E8)],
            ),
          ),
          child: isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'Translating phrases...',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Translate to:",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildLanguageDropdown()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search phrases...',
                        hintStyle: TextStyle(color: subtitleColor),
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        filled: true,
                        fillColor: widget.controller.isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => searchQuery = value.toLowerCase()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: phrasebook.entries.map((entry) {
                    final filteredPhrases = entry.value.where((p) {
                      final text =
                      (p.englishText + p.translatedText).toLowerCase();
                      return searchQuery.isEmpty || text.contains(searchQuery);
                    }).toList();

                    if (filteredPhrases.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        childrenPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getCategoryIcon(entry.key),
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        children: filteredPhrases.map((phrase) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.controller.isDarkMode
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(
                                phrase.englishText,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: phrase.translatedText.isNotEmpty
                                  ? Text(
                                phrase.translatedText,
                                style: TextStyle(color: subtitleColor),
                              )
                                  : null,
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.volume_up, color: primaryColor),
                                      onPressed: () => _speak(
                                        phrase.translatedText.isNotEmpty
                                            ? phrase.translatedText
                                            : phrase.englishText,
                                      ),
                                      tooltip: 'Play Audio',
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: phrase.isFavorite
                                          ? Colors.amber.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        phrase.isFavorite
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: phrase.isFavorite
                                            ? Colors.amber
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() =>
                                        phrase.isFavorite = !phrase.isFavorite);
                                        _saveCachedTranslations();
                                      },
                                      tooltip: phrase.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
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
            currentIndex: _selectedIndex,
            backgroundColor: widget.controller.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            selectedItemColor: widget.controller.isDarkMode ? Colors.white : const Color(0xFF00695C),
            unselectedItemColor: widget.controller.isDarkMode ? Colors.grey[500] : Colors.grey[600],
            type: BottomNavigationBarType.fixed,
            onTap: _onNavTap,
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