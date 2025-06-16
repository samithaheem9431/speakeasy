import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: VoiceTranslatorApp(),
  ));
}

class VoiceTranslatorApp extends StatefulWidget {
  @override
  _VoiceTranslatorAppState createState() => _VoiceTranslatorAppState();
}

class _VoiceTranslatorAppState extends State<VoiceTranslatorApp> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  String _spokenText = '';
  String _translatedText = '';

  String _inputLangCode = 'en';
  String _outputLangCode = 'ur';

  final String apiKey = 'AIzaSyAqhaDvC4RJpu7hVeBSx0Nt1hNv1ycR3pE'; // Replace with your actual API key

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

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) async {
          setState(() => _spokenText = result.recognizedWords);
          if (_spokenText.isNotEmpty) {
            final translation = await _translateText(
              _spokenText,
              _inputLangCode,
              _outputLangCode,
            );
            setState(() => _translatedText = translation);
            await _speakText(_translatedText);
          }
        },
        localeId: _getLocaleId(_inputLangCode),
      );
    }
  }

  String _getLocaleId(String langCode) {
    switch (langCode) {
      case 'ur':
        return 'ur-PK';
      case 'ar':
        return 'ar-SA';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'tr':
        return 'tr-TR';
      case 'de':
        return 'de-DE';
      case 'zh':
        return 'zh-CN';
      default:
        return 'en-US';
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speakText(String text) async {
    await _tts.setLanguage(_outputLangCode);
    await _tts.speak(text);
  }

  Future<String> _translateText(String input, String from, String to) async {
    final Uri url = Uri.parse(
      'https://translation.googleapis.com/language/translate/v2?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': input,
        'source': from,
        'target': to,
        'format': 'text',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['translations'][0]['translatedText'];
    } else {
      throw Exception('Failed to translate text');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Voice Translator App")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text("Input Language"),
                    DropdownButton<String>(
                      value: _inputLangCode,
                      items: languageCodes.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.value,
                          child: Text(entry.key),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _inputLangCode = val!),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text("Output Language"),
                    DropdownButton<String>(
                      value: _outputLangCode,
                      items: languageCodes.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.value,
                          child: Text(entry.key),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _outputLangCode = val!),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? "Stop Listening" : "Start Listening"),
            ),
            SizedBox(height: 20),
            Text("Recognized Text:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_spokenText, style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text("Translated Text:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_translatedText, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
