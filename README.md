# 📚 Smart Board - سبورة ذكية

تطبيق Flutter متكامل للشرح والمذاكرة على التابلت والموبايل.

## المميزات

- ✏️ **الرسم بالقلم** — كتابة حرة بأحجام وألوان مختلفة
- ⌨️ **الكتابة بالكيبورد** — إضافة نصوص قابلة للتحريك
- 📄 **صفحات مسطرة** — مسطّرة، مربعات، نقاط، أو فارغة
- 📚 **نظام الدروس** — كل درس له صفحات محددة
- 🔢 **تنقل بين الصفحات** — سوايب أو أسهم
- 🧪 **صفحة اختبار** — سؤال وإجابة مخفية
- 💾 **حفظ تلقائي** — كل تغيير يُحفظ فوراً
- 🎨 **ألوان متعددة** — 6 ألوان ثابتة + color picker

## تشغيل المشروع

```bash
flutter pub get
flutter run
```

## بناء APK

```bash
flutter build apk --release --no-tree-shake-icons
```

الـ APK هيكون في:
```
build/app/outputs/flutter-apk/app-release.apk
```

## GitHub Actions

الـ workflow بيبني APK تلقائياً عند كل push على main.
روح Actions → اضغط على آخر run → Artifacts → حمّل الـ APK.

## هيكل المشروع

```
lib/
├── main.dart                    # نقطة البداية
├── models/
│   └── models.dart              # Lesson, BoardPage, DrawnStroke, TextNote
├── providers/
│   └── board_provider.dart      # State management
├── screens/
│   ├── home_screen.dart         # شاشة الدروس
│   └── board_screen.dart        # شاشة الرسم
└── widgets/
    ├── toolbar.dart             # شريط الأدوات
    ├── board_painter.dart       # رسم الخطوط والسطور
    ├── page_indicator.dart      # مؤشر الصفحات
    ├── text_note_layer.dart     # طبقة النصوص
    └── quiz_overlay.dart        # صفحة الاختبار
```
