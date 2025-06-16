import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'interstitial_ad_helper.dart';

class TranslatorController {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();
  final TextEditingController textController = TextEditingController();
  late RecorderController recorderController;

  bool isListening = false;
  bool isDarkMode = false;
  bool isTextInput = false;

  String spokenText = '';
  String translatedText = '';
  String inputLangCode = 'en';
  String outputLangCode = 'ur';

  List<Map<String, String>> translationHistory = [];
  int selectedIndex = 0;

  double _lastSoundLevel = 0.0;
  int _silenceCounter = 0;
  final int _silenceLimit = 6;

  static const String _apiKey = 'AIzaSyAqhaDvC4RJpu7hVeBSx0Nt1hNv1ycR3pE'; // Secure this in .env or secure storage

  static const darkColor = Color(0xFF26A69A);
  static const lightColor = Color(0xFF00695C);
  static const snackBarDuration = Duration(seconds: 1);

  final Map<String, String> languageCodes = {
    'English': 'en',
    'Urdu': 'ur',
    'French': 'fr',
    'Spanish': 'es',
    'Turkish': 'tr',
    'Arabic': 'ar',
    'German': 'de',
    'Chinese': 'zh',
  };

  void initialize(BuildContext context, void Function(VoidCallback fn) setState) {
    _requestPermissions();
    _loadThemePreference(setState);
    _loadHistory(setState);

    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..updateFrequency = const Duration(milliseconds: 50)
      ..sampleRate = 16000;

    InterstitialAdHelper.loadAd();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> _loadThemePreference(void Function(VoidCallback fn) setState) async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('isDarkMode') ?? false;
    setState(() {});
  }

  Future<void> _loadHistory(void Function(VoidCallback fn) setState) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('translationHistory');
    if (stored != null) {
      translationHistory = stored.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
      setState(() {});
    }
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'translationHistory',
      translationHistory.map((e) => jsonEncode(e)).toList(),
    );
  }

  void clearHistory(void Function(VoidCallback fn) setState) async {
    translationHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('translationHistory');
    setState(() {});
  }

  void toggleTheme(BuildContext context, void Function(VoidCallback fn) setState) async {
    isDarkMode = !isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    setState(() {});

    _showSnackBar(
      context,
      '${isDarkMode ? "Dark" : "Light"} mode enabled',
      icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
      backgroundColor: isDarkMode ? darkColor : lightColor,
    );
  }

  void swapLanguages(void Function(VoidCallback fn) setState) {
    final temp = inputLangCode;
    inputLangCode = outputLangCode;
    outputLangCode = temp;
    spokenText = '';
    translatedText = '';
    setState(() {});
    HapticFeedback.lightImpact();
  }

  String getLocaleId(String code) {
    const localeMap = {
      'ur': 'ur-PK',
      'ar': 'ar-SA',
      'fr': 'fr-FR',
      'es': 'es-ES',
      'tr': 'tr-TR',
      'de': 'de-DE',
      'zh': 'zh-CN',
      'en': 'en-US',
    };
    return localeMap[code] ?? 'en-US';
  }

  String getLanguageName(String code) {
    return languageCodes.entries.firstWhere((e) => e.value == code).key;
  }

  Future<void> startListening(BuildContext context, void Function(VoidCallback fn) setState) async {
    await tts.stop();

    if (!await isConnected()) {
      _showSnackBar(context, 'No internet. Voice recognition may not work.', icon: Icons.wifi_off, backgroundColor: Colors.orange[600]!);
      return;
    }

    final available = await _speech.initialize();
    if (!available) {
      _showSnackBar(context, 'Speech recognition not available', icon: Icons.mic_off, backgroundColor: Colors.red[600]!);
      return;
    }

    recorderController.record();
    isListening = true;
    _silenceCounter = 0;
    setState(() {});
    HapticFeedback.mediumImpact();

    _speech.listen(
      onResult: (result) async {
        if (result.finalResult) {
          spokenText = result.recognizedWords;
          if (spokenText.isNotEmpty) {
            translatedText = await translateText(spokenText, inputLangCode, outputLangCode, context);
            translationHistory.add({
              'from': spokenText,
              'to': translatedText,
              'lang': '${getLanguageName(inputLangCode)} → ${getLanguageName(outputLangCode)}',
            });
            await saveHistory();
            await speakText(translatedText);
            setState(() {});
            HapticFeedback.lightImpact();
          }
          stopListening(setState);
        }
      },
      onSoundLevelChange: (level) {
        _lastSoundLevel = level;
        _silenceCounter = level < 1.0 ? _silenceCounter + 1 : 0;
        if (_silenceCounter >= _silenceLimit) stopListening(setState);
      },
      localeId: getLocaleId(inputLangCode),
      listenFor: const Duration(seconds: 10),
    );
  }

  void stopListening(void Function(VoidCallback fn) setState) {
    _speech.stop();
    recorderController.stop();
    isListening = false;
    setState(() {});
    HapticFeedback.selectionClick();
  }

  Future<void> speakText(String text) async {
    await tts.setLanguage(outputLangCode);
    await tts.speak(text);
  }

  Future<String> translateText(String input, String from, String to, BuildContext context) async {
    if (!await isConnected()) {
      _showSnackBar(context, 'No internet connection', icon: Icons.wifi_off, backgroundColor: Colors.red[600]!);
      return 'No internet';
    }

    try {
      final response = await http.post(
        Uri.parse('https://translation.googleapis.com/language/translate/v2?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'q': input, 'source': from, 'target': to, 'format': 'text'}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body)['data']['translations'][0]['translatedText'];
        InterstitialAdHelper.trackAndShowIfNeeded();
        _showSnackBar(context, 'Translation completed', icon: Icons.check_circle, backgroundColor: Colors.green[600]!);
        return result;
      } else {
        _showSnackBar(context, 'Translation failed. Please try again.', icon: Icons.error, backgroundColor: Colors.red[600]!);
        return 'Translation failed';
      }
    } catch (_) {
      _showSnackBar(context, 'Translation error occurred', icon: Icons.error, backgroundColor: Colors.red[600]!);
      return 'Translation error';
    }
  }

  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void copyText(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    _showSnackBar(context, 'Copied to clipboard', icon: Icons.copy, backgroundColor: isDarkMode ? darkColor : lightColor);
  }

  void shareText(String text) {
    Share.share(text);
    HapticFeedback.lightImpact();
  }

  void _showSnackBar(BuildContext context, String message, {required IconData icon, required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: snackBarDuration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
