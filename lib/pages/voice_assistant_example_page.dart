import 'package:flutter/material.dart';
import 'voice_assistant_page.dart';
import 'cupping_cups_page.dart';

/// مثال عملي: كيفية إضافة المساعد الصوتي في صفحة رئيسية
/// 
/// هذا الملف يوضح التطبيق العملي للمساعد الصوتي.
/// يمكنك نسخ هذا الكود وإضافته إلى حيث تريد.

class VoiceAssistantExamplePage extends StatefulWidget {
  const VoiceAssistantExamplePage({super.key});

  @override
  State<VoiceAssistantExamplePage> createState() =>
      _VoiceAssistantExamplePageState();
}

class _VoiceAssistantExamplePageState extends State<VoiceAssistantExamplePage> {
  String _lastCommand = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال: المساعد الصوتي'),
        centerTitle: true,
        // إضافة زر الميكروفون في AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'مساعد صوتي',
            onPressed: _showVoiceAssistant,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1️⃣ بطاقة المساعد الصوتي الرئيسية
            _buildMainCard(context),
            const SizedBox(height: 24),

            // 2️⃣ قسم الأمثلة
            _buildExamplesSection(),
            const SizedBox(height: 24),

            // 3️⃣ قسم آخر الأمر
            _buildLastCommandSection(),
            const SizedBox(height: 24),

            // 4️⃣ أزرار سريعة
            _buildQuickButtons(context),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 1️⃣ البطاقة الرئيسية للمساعد الصوتي
  // ========================================
  Widget _buildMainCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: _showVoiceAssistant,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // الأيقونة المتحركة
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4B39EF),
                      Color(0xFF7C4DFF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4B39EF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 45,
                ),
              ),
              const SizedBox(height: 16),

              // العنوان
              const Text(
                '🎤 مساعد صوتي ذكي',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // الوصف
              Text(
                'اضغط للتحدث\nقل "أريد كاسات حجامة"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // زر الفعل
              FilledButton.icon(
                onPressed: _showVoiceAssistant,
                icon: const Icon(Icons.start),
                label: const Text('اضغط هنا'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // 2️⃣ قسم الأمثلة
  // ========================================
  Widget _buildExamplesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💬 أمثلة من الأوامر:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildExampleChip(
          icon: '🩺',
          text: '"أريد كاسات حجامة"',
          description: 'عرض كاسات الحجامة',
        ),
        const SizedBox(height: 8),
        _buildExampleChip(
          icon: '📋',
          text: '"أريد المنتجات"',
          description: 'فتح قائمة المنتجات',
        ),
        const SizedBox(height: 8),
        _buildExampleChip(
          icon: '❓',
          text: '"ساعدني"',
          description: 'عرض المساعدة والأوامر',
        ),
        const SizedBox(height: 8),
        _buildExampleChip(
          icon: '💡',
          text: '"تطبيق"',
          description: 'معلومات عن التطبيق',
        ),
      ],
    );
  }

  Widget _buildExampleChip({
    required String icon,
    required String text,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4B39EF).withOpacity(0.05),
        border: Border.all(
          color: const Color(0xFF4B39EF).withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 3️⃣ قسم آخر أمر تم استقباله
  // ========================================
  Widget _buildLastCommandSection() {
    return Card(
      color: const Color(0xFF4B39EF).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 آخر أمر تم استقباله:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B39EF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _lastCommand.isNotEmpty ? _lastCommand : 'لم يتم استقبال أي أمر حتى الآن',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _lastCommand.isNotEmpty
                    ? const Color(0xFF4B39EF)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 4️⃣ أزرار سريعة
  // ========================================
  Widget _buildQuickButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ أزرار سريعة:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.shopping_bag),
            label: const Text('عرض كاسات الحجامة مباشرة'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CuppingCupsPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.mic),
            label: const Text('فتح المساعد الصوتي في Dialog'),
            onPressed: () {
              showVoiceAssistantDialog(
                context,
                onCommandReceived: (command) {
                  _handleVoiceCommand(command);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ========================================
  // معالجات الأحداث
  // ========================================

  /// فتح المساعد الصوتي في Bottom Sheet
  void _showVoiceAssistant() {
    showVoiceAssistantBottomSheet(
      context,
      onCommandReceived: (command) {
        _handleVoiceCommand(command);
      },
    );
  }

  /// معالجة الأوامر الصوتية
  void _handleVoiceCommand(String command) {
    // تحديث حالة آخر أمر
    setState(() {
      _lastCommand = command;
    });

    // معالجة الأمر
    switch (command) {
      case 'cupping_cups':
        // الانتقال إلى صفحة كاسات الحجامة
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CuppingCupsPage(),
          ),
        );
        break;

      case 'show_menu':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📋 تم فتح القائمة'),
            duration: Duration(seconds: 2),
          ),
        );
        break;

      case 'help':
        _showHelpDialog();
        break;

      case 'app_info':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ℹ️ تطبيق مستلزمات النخلة'),
            duration: Duration(seconds: 2),
          ),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم استقبال الأمر: $command'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  /// عرض نافذة المساعدة
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('❓ المساعدة'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الأوامر الصوتية المتاحة:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text('• قل "أريد كاسات حجامة" لعرض الكاسات'),
              SizedBox(height: 8),
              Text('• قل "ساعدني" للمساعدة'),
              SizedBox(height: 8),
              Text('• قل "تطبيق" لمعرفة عن التطبيق'),
              SizedBox(height: 8),
              Text('• قل "أريد" لفتح القائمة'),
              SizedBox(height: 16),
              Text(
                'نصائح:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text('✓ تحدث بوضوح'),
              SizedBox(height: 4),
              Text('✓ تأكد من الإنترنت'),
              SizedBox(height: 4),
              Text('✓ استخدم الإنجليزية أو العربية'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}

// ========================================
// مثال على الاستخدام في main.dart
// ========================================

/*
// في main.dart، يمكنك استخدام هذه الصفحة كالتالي:

// 1. أضف الاستيراد:
import 'pages/voice_assistant_example_page.dart';

// 2. استخدمها كـ home:
home: const VoiceAssistantExamplePage(),

// أو أضفها كـ tab في navigation:
const VoiceAssistantExamplePage(), // في قائمة _pages

// مع إضافة في navigation destinations:
NavigationDestination(
  icon: Icon(Icons.mic),
  label: 'صوت',
),
*/
