import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech-to-text + text-to-speech wrapper, locked to Thai.
///
/// Both libraries delegate to the OS: on iOS it's Siri's recognizer,
/// on Android it's Google's offline/online recognizer. No cloud STT
/// service is called — privacy-friendly and works without network on
/// most devices.
class VoiceService {
  VoiceService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttReady = false;
  bool _ttsReady = false;

  Future<bool> initStt() async {
    if (_sttReady) return true;
    try {
      _sttReady = await _stt.initialize(
        onError: (e) => _logger.w('STT error', error: e),
        onStatus: (s) => _logger.d('STT status: $s'),
      );
    } catch (e) {
      _logger.w('STT init failed', error: e);
      _sttReady = false;
    }
    return _sttReady;
  }

  Future<void> initTts() async {
    if (_ttsReady) return;
    try {
      await _tts.setLanguage('th-TH');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _ttsReady = true;
    } catch (e) {
      _logger.w('TTS init failed', error: e);
      _ttsReady = false;
    }
  }

  bool get isListening => _stt.isListening;

  /// Start recognition; the callback fires for every partial and the
  /// final result. Returns false if STT couldn't start.
  Future<bool> startListening({
    required void Function(String text, bool finalResult) onResult,
  }) async {
    if (!await initStt()) return false;
    try {
      await _stt.listen(
        localeId: 'th_TH',
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
        onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      );
      return true;
    } catch (e) {
      _logger.w('STT listen failed', error: e);
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    await initTts();
    if (!_ttsReady) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      _logger.w('TTS speak failed', error: e);
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
