# 🏀 Basketball Controller - Flutter App

تحويل كامل من HTML إلى Flutter APK

---

## 📁 ملفات المشروع

```
basketball_controller/
├── lib/
│   ├── main.dart              ← نقطة البداية
│   ├── firebase_options.dart  ← إعدادات Firebase
│   ├── game_state.dart        ← نموذج البيانات
│   ├── controller_screen.dart ← الشاشة الرئيسية
│   └── edit_modal.dart        ← شاشة التعديل
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml
└── pubspec.yaml
```

---

## 🚀 طريقتان لبناء الـ APK

---

## الطريقة 1: Codemagic (مجاني - بدون تثبيت أي حاجة)

### الخطوات:

**1. ارفع المشروع على GitHub**
- روح على https://github.com
- عمل account جديد لو مش عندك
- اعمل repository جديد اسمه `basketball-controller`
- ارفع كل الملفات

**2. سجّل في Codemagic**
- روح على https://codemagic.io
- سجّل بحساب GitHub
- اختار المشروع

**3. Configure البيناء**
- اختار Flutter App
- Build format: APK
- اضغط Start Build

**4. حمّل الـ APK**
- بعد 5-10 دقائق هتلاقي APK جاهز للتحميل

---

## الطريقة 2: محلي على Windows

### متطلبات:
- Windows 10/11
- 8GB RAM على الأقل
- 15GB مساحة فاضية

### الخطوات:

**1. نزّل Flutter**
```
https://flutter.dev/docs/get-started/install/windows
```
- فك الضغط في `C:\flutter`
- ضيف `C:\flutter\bin` لـ PATH

**2. نزّل Android Studio**
```
https://developer.android.com/studio
```
- ثبّته عادي
- افتح SDK Manager
- نزّل Android SDK (API 33+)

**3. قبول licenses**
```bash
flutter doctor --android-licenses
```

**4. تحقق إن كل حاجة تمام**
```bash
flutter doctor
```

**5. داخل مجلد المشروع:**
```bash
cd basketball_controller
flutter pub get
flutter build apk --release
```

**6. الـ APK هتلاقيه في:**
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 تثبيت الـ APK على Android

1. انقل الـ APK للتليفون (USB أو WhatsApp)
2. روح Settings → Security
3. فعّل "Install from Unknown Sources"
4. افتح الـ APK واتبع التعليمات

---

## ✨ مميزات التطبيق

- ✅ شاشة أفقية ثابتة دايماً
- ✅ الشاشة ما بتقفلش (Wakelock)
- ✅ Firebase real-time sync مع شاشة العرض
- ✅ نفس جميع وظائف HTML الأصلي
- ✅ Shot clock مع تعداد تنازلي
- ✅ Main clock
- ✅ أزرار +1 +2 +3 للفريقين
- ✅ إدارة الأخطاء (Fouls)
- ✅ ربع اللعبة (Quarter)
- ✅ زر Bravo 🎉
- ✅ وضع التعديل الكامل

---

## 🔥 Firebase

المشروع بيستخدم نفس Firebase الموجود في الكود الأصلي:
- Project: ok-new-7c868
- Database: ok-new-7c868-default-rtdb
- البيانات بتتبعت لـ `live` node

---

## ⚠️ ملاحظة مهمة

لو بنيت APK من Codemagic، لازم تضيف google-services.json:
1. روح Firebase Console
2. Project Settings
3. نزّل google-services.json
4. حطّه في `android/app/google-services.json`
