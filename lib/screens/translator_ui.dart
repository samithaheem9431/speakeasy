import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'translator_controller.dart';

extension TranslatorUI on TranslatorController {
  Widget buildTranslatorBody(BuildContext context, Color primaryColor, void Function(VoidCallback) setState) {
    final isDark = isDarkMode;
    final accentColor = isDark ? const Color(0xFF4DB6AC) : const Color(0xFF26A69A);
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: isDark ? 6 : 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Language Selection",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("From", style: TextStyle(color: mutedColor, fontSize: 12)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: inputLangCode,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: languageCodes.entries
                                      .map((e) => DropdownMenuItem(
                                      value: e.value,
                                      child: Text(e.key, style: const TextStyle(fontSize: 14))
                                  ))
                                      .toList(),
                                  onChanged: (val) => setState(() => inputLangCode = val!),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.swap_horiz, color: primaryColor),
                            onPressed: () => swapLanguages(setState),
                            tooltip: "Swap Languages",
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("To", style: TextStyle(color: mutedColor, fontSize: 12)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: outputLangCode,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: languageCodes.entries
                                      .map((e) => DropdownMenuItem(
                                      value: e.value,
                                      child: Text(e.key, style: const TextStyle(fontSize: 14))
                                  ))
                                      .toList(),
                                  onChanged: (val) => setState(() => outputLangCode = val!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: isDark ? 6 : 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => isTextInput = false),
                          icon: const Icon(Icons.mic_rounded),
                          label: const Text("Voice Input"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isTextInput ? primaryColor : mutedColor?.withOpacity(0.3),
                            foregroundColor: !isTextInput ? Colors.white : mutedColor,
                            elevation: !isTextInput ? 3 : 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => isTextInput = true),
                          icon: const Icon(Icons.keyboard_rounded),
                          label: const Text("Text Input"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isTextInput ? primaryColor : mutedColor?.withOpacity(0.3),
                            foregroundColor: isTextInput ? Colors.white : mutedColor,
                            elevation: isTextInput ? 3 : 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Input Section
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isTextInput
                  ? _buildTextInputUI(context, primaryColor, setState)
                  : _buildVoiceInputUI(context, primaryColor, setState),
            ),

            const SizedBox(height: 20),

            // Clear Button
            if (spokenText.isNotEmpty || translatedText.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    spokenText = '';
                    translatedText = '';
                  }),
                  icon: const Icon(Icons.clear_rounded),
                  label: const Text("Clear Output"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[400],
                  ),
                ),
              ),

            // Results Section
            if (spokenText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: isDark ? 6 : 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              getLanguageName(inputLangCode),
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded),
                            onPressed: () => tts.setLanguage(inputLangCode).then((_) => tts.speak(spokenText)),
                            style: IconButton.styleFrom(
                              backgroundColor: primaryColor.withOpacity(0.1),
                              foregroundColor: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        spokenText,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (translatedText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                elevation: isDark ? 6 : 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              getLanguageName(outputLangCode),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded),
                                onPressed: () => speakText(translatedText),
                                style: IconButton.styleFrom(
                                  backgroundColor: accentColor.withOpacity(0.1),
                                  foregroundColor: accentColor,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded),
                                onPressed: () => copyText(translatedText, context),
                                style: IconButton.styleFrom(
                                  backgroundColor: accentColor.withOpacity(0.1),
                                  foregroundColor: accentColor,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_rounded),
                                onPressed: () => shareText(translatedText),
                                style: IconButton.styleFrom(
                                  backgroundColor: accentColor.withOpacity(0.1),
                                  foregroundColor: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          translatedText,
                          key: ValueKey(translatedText),
                          style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputUI(BuildContext context, Color primaryColor, void Function(VoidCallback) setState) {
    return Card(
      elevation: isDarkMode ? 6 : 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.edit_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Text Input",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                labelText: "Enter text to translate",
                labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
                filled: true,
                fillColor: primaryColor.withOpacity(0.05),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => textController.clear(),
                  style: IconButton.styleFrom(
                    foregroundColor: primaryColor.withOpacity(0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (textController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter text to translate'),
                      backgroundColor: Colors.orange[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                  return;
                }
                spokenText = textController.text;
                translatedText = await translateText(spokenText, inputLangCode, outputLangCode, context);
                translationHistory.add({
                  'from': spokenText,
                  'to': translatedText,
                  'lang': '${getLanguageName(inputLangCode)} → ${getLanguageName(outputLangCode)}',
                });
                await saveHistory();
                await speakText(translatedText);
                setState(() {});
              },
              icon: const Icon(Icons.translate_rounded),
              label: const Text("Translate"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceInputUI(BuildContext context, Color primaryColor, void Function(VoidCallback) setState) {
    return Card(
      elevation: isDarkMode ? 6 : 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  isListening ? "Listening..." : "Voice Input",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => isListening ? stopListening(setState) : startListening(context, setState),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isListening
                        ? [primaryColor.withOpacity(0.8), primaryColor]
                        : [primaryColor.withOpacity(0.7), primaryColor.withOpacity(0.9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: isListening ? 20 : 10,
                      spreadRadius: isListening ? 5 : 2,
                    ),
                  ],
                ),
                child: isListening
                    ? Lottie.asset(
                  'assets/listening.json',
                  key: const ValueKey('active'),
                  fit: BoxFit.cover,
                )
                    : const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isListening ? "Tap to stop recording" : "Tap to start recording",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            if (isListening)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AudioWaveforms(
                  enableGesture: false,
                  size: const Size(double.infinity, 60),
                  recorderController: recorderController,
                  waveStyle: WaveStyle(
                    waveColor: primaryColor,
                    extendWaveform: true,
                    showMiddleLine: false,
                    waveThickness: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}