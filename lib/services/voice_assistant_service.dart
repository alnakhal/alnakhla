import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceAssistantService {
  static final VoiceAssistantService _instance = VoiceAssistantService._internal();

  factory VoiceAssistantService() {
    return _instance;
  }

  VoiceAssistantService._internal();

  final FlutterTts _tts = FlutterTts();
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  String _lastHeardText = '';
  final List<String> _commandHistory = [];

  // Stream controllers for UI updates
  final StreamController<String> _recognizedTextStream = StreamController<String>.broadcast();
  final StreamController<bool> _listeningStateStream = StreamController<bool>.broadcast();
  final StreamController<String> _commandStream = StreamController<String>.broadcast();

  Stream<String> get recognizedTextStream => _recognizedTextStream.stream;
  Stream<bool> get listeningStateStream => _listeningStateStream.stream;
  Stream<String> get commandStream => _commandStream.stream;

  bool get isListening => _isListening;
  String get lastHeardText => _lastHeardText;

  // أوامر محددة مسبقاً
  static const Map<String, String> arabicCommands = {
    'كاسات حجامة': 'cupping_cups',
    'أريد كاسات حجامة': 'cupping_cups',
    'اريد كاسات حجامة': 'cupping_cups',
    'أريد حجامة': 'cupping_cups',
    'اريد حجامة': 'cupping_cups',
    'حجامة': 'cupping_cups',
    'أريد': 'show_menu',
    'اريد': 'show_menu',
    'تطبيق': 'app_info',
    'مساعدة': 'help',
    'ساعدني': 'help',
  };

  /// تهيئة خدمة المساعد الصوتي
  Future<void> initialize() async {
    _speechToText = stt.SpeechToText();
    
    // تهيئة TTS
    await _tts.setLanguage("ar-SA");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    
    // تهيئة STT (Speech to Text)
    bool available = await _speechToText.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
      },
    );

    if (!available) {
      print('Speech to text not available');
    }
  }

  /// بدء الاستماع للصوت
  Future<void> startListening() async {
    if (!_isListening && _speechToText.isAvailable) {
      _isListening = true;
      _listeningStateStream.add(true);

      _speechToText.listen(
        onResult: (result) {
          _lastHeardText = result.recognizedWords;
          _recognizedTextStream.add(_lastHeardText);

          // إذا كان الكلام نهائياً، تحقق من الأمر
          if (result.finalResult) {
            _processCommand(_lastHeardText);
            _isListening = false;
            _listeningStateStream.add(false);
          }
        },
        localeId: 'ar_SA',
      );
    }
  }

  /// إيقاف الاستماع
  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speechToText.stop();
      _listeningStateStream.add(false);
    }
  }

  /// معالجة الأوامر
  void _processCommand(String text) {
    String? commandKey;
    String matchedCommand = text;

    // ابحث عن الأوامر المعرّفة
    for (var command in arabicCommands.keys) {
      if (text.contains(command)) {
        commandKey = arabicCommands[command];
        matchedCommand = command;
        break;
      }
    }

    if (commandKey != null) {
      _commandHistory.add(text);
      _commandStream.add(commandKey);
      _respondToCommand(commandKey, matchedCommand);
    } else {
      speak('آسف، لم أفهم الأمر. حاول مرة أخرى');
    }
  }

  /// الرد على الأمر الصوتي
  void _respondToCommand(String command, String matchedText) {
    switch (command) {
      case 'cupping_cups':
        speak('جاري عرض كاسات الحجامة لك');
        break;
      case 'show_menu':
        speak('افتح القائمة الرئيسية');
        break;
      case 'app_info':
        speak('هذا تطبيق مستلزمات النخلة للحجامة والمنتجات الطبية');
        break;
      case 'help':
        speak('قل أريد كاسات حجامة أو أي منتج تريده');
        break;
      default:
        speak('أمر غير معروف');
    }
  }

  /// تشغيل الصوت (TTS)
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
    }
  }

  /// إيقاف التحدث
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  /// الحصول على سجل الأوامر
  List<String> getCommandHistory() => List.from(_commandHistory);

  /// مسح السجل
  void clearHistory() {
    _commandHistory.clear();
  }

  /// تنظيف الموارد
  Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
    await _recognizedTextStream.close();
    await _listeningStateStream.close();
    await _commandStream.close();
  }

  /// البحث عن كاسات حجامة
  Map<String, dynamic> searchCuppingCups() {
    return {
      'command': 'cupping_cups',
      'description': 'عرض كاسات الحجامة المتاحة',
      'icon': '🩺',
    };
  }

  /// إضافة أمر مخصص
  void addCustomCommand(String phrase, String commandKey) {
    arabicCommands[phrase] = commandKey;
  }

  /// الحصول على قائمة الأوامر المتاحة
  Map<String, String> getAvailableCommands() {
    return Map.from(arabicCommands);
  }
}
