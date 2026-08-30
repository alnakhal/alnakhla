# 🎤 المساعد الصوتي الذكي - دليل استخدام شامل

## مرحباً بك! 👋

تم إضافة **مساعد صوتي ذكي** متكامل إلى تطبيق مستلزمات النخلة. عندما يقول العميل "أريد كاسات حجامة"، سيستجيب التطبيق تلقائياً وعرض كاسات الحجامة المتاحة.

---

## 📋 الملفات المضافة الجديدة

| الملف | الوصف |
|------|-------|
| `lib/services/voice_assistant_service.dart` | خدمة المساعد الصوتي الأساسية |
| `lib/pages/voice_assistant_page.dart` | واجهة المساعد الصوتي (الـ UI) |
| `lib/pages/cupping_cups_page.dart` | صفحة عرض كاسات الحجامة |
| `lib/VOICE_ASSISTANT_INTEGRATION.txt` | أمثلة التكامل |

---

## 🚀 خطوات التشغيل الأولية

### 1️⃣ تثبيت المكتبات

تم إضافة المكتبات الآتية تلقائياً في `pubspec.yaml`:

```yaml
dependencies:
  speech_to_text: ^7.0.0  # لتحويل الكلام إلى نص
  flutter_tts: ^4.2.5      # لتحويل النص إلى كلام
```

قم بتشغيل الأمر:

```bash
flutter pub get
```

### 2️⃣ إضافة الأذونات

تم تعديل الملفات التالية تلقائياً:

✅ **Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

✅ **iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSMicrophoneUsageDescription</key>
<string>تطبيق مستلزمات النخلة يحتاج إلى الوصول إلى الميكروفون لاستخدام المساعد الصوتي</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>تطبيق مستلزمات النخلة يحتاج إلى خدمة التعرف على الكلام للمساعد الصوتي</string>
```

### 3️⃣ استيراد الملفات الجديدة في `main.dart`

أضف هذه السطور في أعلى ملف `main.dart`:

```dart
import 'pages/voice_assistant_page.dart';
import 'pages/cupping_cups_page.dart';
import 'services/voice_assistant_service.dart';
```

---

## 🎯 الأوامر الصوتية المتاحة حالياً

| الأمر | الاستجابة | الوصف |
|------|----------|-------|
| **أريد كاسات حجامة** | عرض كاسات الحجامة | عرض جميع أنواع كاسات الحجامة المتاحة |
| **اريد كاسات حجامة** (بدون همزة) | عرض كاسات الحجامة | نفس الأمر السابق |
| **حجامة** | عرض كاسات الحجامة | اختصار للأمر السابق |
| **أريد المنتجات** | فتح قائمة المنتجات | عرض المنتجات |
| **ساعدني** | عرض المساعدة | عرض تعليمات الاستخدام |

---

## 💻 كيفية الاستخدام

### الطريقة 1️⃣: عرض المساعد الصوتي في Bottom Sheet

```dart
import 'pages/voice_assistant_page.dart';

// في أي مكان بالكود:
showVoiceAssistantBottomSheet(
  context,
  onCommandReceived: (command) {
    // معالجة الأمر
    if (command == 'cupping_cups') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CuppingCupsPage()),
      );
    }
  },
);
```

### الطريقة 2️⃣: عرض المساعد الصوتي في Dialog

```dart
showVoiceAssistantDialog(
  context,
  onCommandReceived: (command) {
    print('تم استقبال الأمر: $command');
    // معالجة الأمر
  },
);
```

### الطريقة 3️⃣: إضافة زر في AppBar

```dart
AppBar(
  title: const Text('مستلزمات حجامة النخلة'),
  actions: [
    IconButton(
      icon: const Icon(Icons.mic),
      tooltip: 'مساعد صوتي',
      onPressed: () {
        showVoiceAssistantBottomSheet(context, 
          onCommandReceived: (command) {
            _handleVoiceCommand(command);
          },
        );
      },
    ),
  ],
),
```

### الطريقة 4️⃣: إضافة زر في الصفحة الرئيسية

```dart
Card(
  child: InkWell(
    onTap: () {
      showVoiceAssistantBottomSheet(context,
        onCommandReceived: (command) {
          _handleVoiceCommand(command);
        },
      );
    },
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4B39EF),
                  const Color(0xFF7C4DFF),
                ],
              ),
            ),
            child: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'مساعد صوتي ذكي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'اضغط لتقول أريد كاسات حجامة',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  ),
)
```

---

## ⚙️ خدمة المساعد الصوتي المتقدمة

### الوصول إلى الخدمة مباشرة

```dart
final voiceService = VoiceAssistantService();
await voiceService.initialize();
```

### الاستماع للأوامر

```dart
voiceService.commandStream.listen((command) {
  print('تم استقبال الأمر: $command');
  // معالجة الأمر
});
```

### الاستماع لحالة الاستماع

```dart
voiceService.listeningStateStream.listen((isListening) {
  if (isListening) {
    print('جاري الاستماع...');
  } else {
    print('توقف الاستماع');
  }
});
```

### الاستماع للنصوص المعروفة

```dart
voiceService.recognizedTextStream.listen((text) {
  print('النص المعروف: $text');
});
```

### إضافة أوامر مخصصة

```dart
voiceService.addCustomCommand('أريد كريمات', 'cream_products');
voiceService.addCustomCommand('أريد زيوت', 'oils');
voiceService.addCustomCommand('عرض السلة', 'show_cart');
```

### الحصول على قائمة الأوامر

```dart
final commands = voiceService.getAvailableCommands();
commands.forEach((key, value) {
  print('$key → $value');
});
```

### تشغيل الصوت (Text-to-Speech)

```dart
voiceService.speak('مرحباً! كيف يمكنني مساعدتك؟');
```

### بدء وإيقاف الاستماع

```dart
// البدء
voiceService.startListening();

// الإيقاف
voiceService.stopListening();
```

---

## 📱 صفحة كاسات الحجامة

تم إنشاء صفحة متقدمة لعرض كاسات الحجامة مع:
- تصميم جميل بألوان متناسقة
- بطاقات منتجات تفاعلية
- زر "أضف للسلة"
- زر "إضافة للمفضلة"
- عرض السعر والوصف

```dart
// الدخول إلى صفحة كاسات الحجامة
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const CuppingCupsPage()),
);
```

---

## 🎨 تخصيص الأوامر والاستجابات

### تغيير الأوامر المتاحة

في ملف `services/voice_assistant_service.dart`، عدّل الـ Map:

```dart
static const Map<String, String> arabicCommands = {
  'كاسات حجامة': 'cupping_cups',
  'أريد كاسات حجامة': 'cupping_cups',
  // أضف أوامرك هنا
  'أريد منتجاتك': 'show_products',
  'سعر الشحن': 'shipping_info',
};
```

### تغيير الاستجابة الصوتية

```dart
voiceService.speak('شكراً لاختيارك كاسات الحجامة!');
```

---

## 🐛 استكشاف الأخطاء

### المساعد الصوتي لا يعمل؟

1. تأكد من تثبيت المكتبات:
   ```bash
   flutter pub get
   ```

2. تأكد من الأذونات:
   - Android: تحقق من `AndroidManifest.xml`
   - iOS: تحقق من `Info.plist`

3. تحقق من السماح بالوصول للميكروفون في إعدادات الهاتف

4. جرب في جهاز حقيقي (قد لا يعمل في المحاكي)

### الكلام لا يتم التعرف عليه؟

- تحدث بوضوح وببطء
- تأكد من وجود إنترنت (مطلوب لـ Speech Recognition)
- اللغة الحالية مضبوطة على العربية (`ar_SA`)

### النطق غير واضح؟

- عدّل السرعة: `await _tts.setSpeechRate(0.5);`
- عدّل مستوى الصوت

---

## 📊 الأحداث والـ Streams

### التدفقات (Streams) المتاحة

```dart
// نص معروف من الكلام
voiceService.recognizedTextStream; // Stream<String>

// حالة الاستماع (يستمع أم لا)
voiceService.listeningStateStream; // Stream<bool>

// الأوامر المستقبلة
voiceService.commandStream; // Stream<String>
```

---

## 🔐 الخصوصية والأمان

- جميع معالجة الكلام تتم محلياً على الجهاز
- لا يتم حفظ تسجيلات صوتية
- يمكن إيقاف الاستماع في أي وقت
- الأذونات تطلب الموافقة من المستخدم

---

## 📞 دعم اللغات

حالياً يدعم المساعد الصوتي:
- ✅ العربية (ar_SA)
- 📝 يمكن إضافة لغات أخرى

لإضافة لغة أخرى:

```dart
// في VoiceAssistantService.initialize()
await _tts.setLanguage("en-US");
```

---

## 🎯 الخطوات التالية (اختيارية)

### 1. إضافة أوامر أكثر

أضف أوامر جديدة مثل:
- "أريد كريمات"
- "أريد زيوت عطرية"
- "أريد الأسعار"
- "أريد الشروط"

### 2. ربط الأوامر بقاعدة البيانات

ابحث عن المنتجات تلقائياً حسب الأمر الصوتي

### 3. إضافة تعليقات صوتية

أضف صوت عند عرض المنتجات

### 4. دعم لغات أخرى

أضف دعم الإنجليزية أو لغات أخرى

---

## ✨ نصائح مهمة

1. **الاختبار**: اختبر المساعد الصوتي على جهاز حقيقي
2. **الأداء**: الخدمة تعمل بشكل فعال ولا تؤثر على الأداء
3. **الخصوصية**: أخبر المستخدمين بأن التطبيق يستخدم الميكروفون
4. **التحديثات**: يمكن تحديث الأوامر بسهولة

---

## 📚 المراجع والموارد

- [speech_to_text package](https://pub.dev/packages/speech_to_text)
- [flutter_tts package](https://pub.dev/packages/flutter_tts)
- [Flutter Documentation](https://flutter.dev)

---

## ✅ الخلاصة

تم بنجاح:
1. ✅ إضافة خدمة المساعد الصوتي
2. ✅ إنشاء واجهة مستخدم جميلة
3. ✅ إضافة أوامر صوتية عربية
4. ✅ إنشاء صفحة كاسات الحجامة
5. ✅ تكوين الأذونات
6. ✅ توثيق شامل

---

## 🎉 استمتع بالمساعد الصوتي!

الآن يمكن للعملاء قول **"أريد كاسات حجامة"** والتطبيق سيستجيب تلقائياً! 🎤✨

---

**آخر تحديث**: 2026-08-30
**الإصدار**: 1.0.0
