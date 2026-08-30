import 'package:flutter/material.dart';
import '../services/voice_assistant_service.dart';

class VoiceAssistantWidget extends StatefulWidget {
  final Function(String)? onCommandReceived;
  final VoiceAssistantService? service;

  const VoiceAssistantWidget({
    Key? key,
    this.onCommandReceived,
    this.service,
  }) : super(key: key);

  @override
  State<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget>
    with TickerProviderStateMixin {
  late VoiceAssistantService _voiceService;
  bool _isListening = false;
  String _recognizedText = '';
  late AnimationController _pulseController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _voiceService = widget.service ?? VoiceAssistantService();
    _initializeService();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Animation للنبض
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Animation للحركة
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  Future<void> _initializeService() async {
    await _voiceService.initialize();

    // الاستماع للتغييرات
    _voiceService.recognizedTextStream.listen((text) {
      setState(() => _recognizedText = text);
    });

    _voiceService.listeningStateStream.listen((isListening) {
      setState(() => _isListening = isListening);
      if (isListening) {
        _pulseController.forward(from: 0.0);
      }
    });

    _voiceService.commandStream.listen((command) {
      widget.onCommandReceived?.call(command);
      _showCommandNotification(command);
    });
  }

  void _showCommandNotification(String command) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getCommandText(command)),
        backgroundColor: const Color(0xFF4B39EF),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getCommandText(String command) {
    switch (command) {
      case 'cupping_cups':
        return '🩺 جاري عرض كاسات الحجامة';
      case 'show_menu':
        return '📋 فتح القائمة';
      case 'app_info':
        return 'ℹ️ معلومات التطبيق';
      case 'help':
        return '❓ المساعدة';
      default:
        return '✅ تم الاستقبال: $command';
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _voiceService.stopListening();
    } else {
      _voiceService.startListening();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر الميكروفون الرئيسي
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4B39EF)
                          .withOpacity(_isListening ? 0.4 : 0.1),
                      blurRadius: _isListening ? 30 : 10,
                      spreadRadius: _isListening ? _pulseController.value * 20 : 0,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isListening
                            ? [
                                const Color(0xFF4B39EF),
                                const Color(0xFF7C4DFF),
                              ]
                            : [
                                const Color(0xFF4B39EF).withOpacity(0.7),
                                const Color(0xFF00BFA6).withOpacity(0.7),
                              ],
                      ),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // نص الحالة
          Text(
            _isListening ? '🎤 جاري الاستماع...' : '📢 اضغط للتحدث',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _isListening
                      ? const Color(0xFF4B39EF)
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),

          // النص المعروف
          if (_recognizedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4B39EF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4B39EF).withOpacity(0.3),
                ),
              ),
              child: Text(
                '"$_recognizedText"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4B39EF),
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // الأوامر المتاحة (عند عدم الاستماع)
          if (!_isListening)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Text(
                    'أوامر متاحة:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildCommandChip('🩺 كاسات حجامة'),
                      _buildCommandChip('📋 القائمة'),
                      _buildCommandChip('❓ مساعدة'),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommandChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFF4B39EF).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF4B39EF),
            ),
      ),
    );
  }
}

/// عرض المساعد الصوتي في Dialog
void showVoiceAssistantDialog(BuildContext context, {Function(String)? onCommandReceived}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: VoiceAssistantWidget(
          onCommandReceived: (command) {
            onCommandReceived?.call(command);
            Navigator.pop(context);
          },
        ),
      ),
    ),
  );
}

/// عرض المساعد الصوتي في Bottom Sheet
void showVoiceAssistantBottomSheet(BuildContext context, {Function(String)? onCommandReceived}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => VoiceAssistantWidget(
      onCommandReceived: (command) {
        onCommandReceived?.call(command);
        Navigator.pop(context);
      },
    ),
  );
}
