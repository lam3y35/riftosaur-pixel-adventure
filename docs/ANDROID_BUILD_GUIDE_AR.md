# دليل بناء وتصدير نسخة الأندرويد للعبة Riftosaur (للمطورين والمالك)

يشرح هذا الدليل بالتفصيل كيفية إعداد بيئة بناء أندرويد وتصدير ملفات التثبيت (APK) للعبة **Riftosaur** باستخدام محرك **Godot 4.7.2** الرسمي.

---

## 1. المتطلبات البرمجية والنسخ المعتمدة

| البرنامج | النسخة المعتمدة | مسار التثبيت المحلي | المصدر الرسمي |
|---|---|---|---|
| **Godot Engine** | `4.7.2.stable.official` | `C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe` | [godotengine.org](https://godotengine.org) |
| **قوالب التصدير** | `4.7.2.stable` | `%APPDATA%\Godot\export_templates\4.7.2.stable\` | مدمجة ومطابقة رسمياً |
| **Java JDK** | `17.0.20 Microsoft Hotspot` | `C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot\` | [Microsoft Build of OpenJDK](https://learn.microsoft.com/en-us/java/openjdk/download) |
| **Android SDK** | `API 34 (Android 14)` | `C:\Users\Tweety\AppData\Local\Android\Sdk` | [Google Android Developers](https://developer.android.com/studio#command-tools) |
| **Build Tools** | `34.0.0` (aapt2, zipalign, apksigner) | `C:\Users\Tweety\AppData\Local\Android\Sdk\build-tools\34.0.0\` | عبر `sdkmanager` |
| **Platform Tools**| `37.0.1 (adb 1.0.41)` | `C:\Users\Tweety\AppData\Local\Android\Sdk\platform-tools\` | عبر Google |

---

## 2. إعداد مسارات أندرويد في محرك Godot

1. افتح محرك Godot 4.7.2.
2. من القائمة العلوية اختر: **Editor** -> **Editor Settings**.
3. ابحث في الشريط الجانبي عن **Export** -> **Android**:
   - **Android SDK Path:** ضع المسار:
     `C:\Users\Tweety\AppData\Local\Android\Sdk`
   - **Java SDK Path:** ضع المسار:
     `C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot`
   - **Debug Keystore:** ضع المسار:
     `C:\Users\Tweety\AppData\Roaming\Godot\keystores\debug.keystore`
   - **Debug Keystore User:** `androiddebugkey`
   - **Debug Keystore Password:** `android`

---

## 3. الفرق بين بناء التطوير (Debug) وبناء النشر (Release)

| الخاصية | نسخة التطوير (Debug APK) | نسخة النشر النهائي (Release APK/AAB) |
|---|---|---|
| **الغرض** | التجربة السريعة واختبار المالك والأصدقاء | النشر على المتاجر ومشاركة الإصدارات المستقرة |
| **مفتاح التوقيع** | مفتاح عام تلقائي (`debug.keystore`) | مفتاح سري خاص بالمالك (`release.keystore`) |
| **تتبع الأخطاء** | يحتوي على رسائل تتبع الأخطاء وسجل `adb logcat` | معطل التتبع لزيادة الأداء وسرعة التشغيل |
| **حجم التطبيق** | أكبر قليلاً لاحتوائه على أدوات الفحص | أصغر حجماً ومضغوط بالكامل |

> **تحذير أمان للمالك:** مفتاح التوقيع السري للنسخة النهائية (`release.keystore`) هو هويتك الوحيدة لدى نظام أندرويد. إذا فُقد المفتاح، لن يتمكن أي لاعب من تحديث اللعبة فوق نسخته المثبتة أبداً. احتفظ بنسخة احتياطية مشفرة منه دائماً فور إنشائه (في Session 12).

---

## 4. خطوات تصدير ملف APK

### الطريقة الأولى: من خلال محرر Godot (واجهة رسومية)
1. افتح مشروع `Riftosaur` في Godot.
2. من القائمة العلوية اختر **Project** -> **Export...**.
3. ستجد الإعداد الافتراضي جاهزاً باسم **Android Debug**.
4. اضغط على زر **Export Project...** في الأسفل.
5. حدد مسار الحفظ في مجلد `releases/Riftosaur-debug.apk` واضغط Save.

### الطريقة الثانية: من سطر الأوامر (PowerShell تم اختباره)
نفّذ الأمر التالي من مجلد المشروع `C:\Users\Tweety\Desktop\DINO`:
```powershell
& "C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --export-debug "Android Debug" releases/Riftosaur-debug.apk
```

---

## 5. فحص والتحقق من ملف الـ APK بعد البناء (L4 Static Verification)

بعد انتهاء عملية التصدير، يتم التحقق الإلزامي من 5 عناصر:
```powershell
# 1. التحقق من وجود الملف وحساب البصمة الرقمية (SHA-256)
Get-FileHash -Path releases/Riftosaur-debug.apk -Algorithm SHA256

# 2. فحص بيانات الحزمة والصلاحيات والمعمارية (arm64-v8a)
& "C:\Users\Tweety\AppData\Local\Android\Sdk\build-tools\34.0.0\aapt2.exe" dump badging releases/Riftosaur-debug.apk

# 3. التحقق من المحاذاة (Zipalign)
& "C:\Users\Tweety\AppData\Local\Android\Sdk\build-tools\34.0.0\zipalign.exe" -c -v 4 releases/Riftosaur-debug.apk

# 4. التحقق من التوقيع الرقمي والشهادة
& "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot\bin\java.exe" -jar "C:\Users\Tweety\AppData\Local\Android\Sdk\build-tools\34.0.0\lib\apksigner.jar" verify --print-certs releases/Riftosaur-debug.apk
```
