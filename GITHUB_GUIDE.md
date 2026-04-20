# دليل رفع المشروع وبناء APK على GitHub

لقد قمت بتحديث المشروع وإضافة مجلد Android مع أحدث الإعدادات المتوافقة لعام 2024/2025.

## خطوات رفع المشروع إلى GitHub:

1. قم بإنشاء مستودع (Repository) جديد على GitHub.
2. افتح المجلد في جهازك واستخدم الأوامر التالية:
   ```bash
   git init
   git add .
   git commit -m "Initial commit with Android support and updated dependencies"
   git branch -M main
   git remote add origin [رابط_المستودع_الخاص_بك]
   git push -u origin main
   ```

## كيفية بناء ملف APK:

1. بمجرد رفع الكود إلى فرع `main`، سيبدأ GitHub Actions بالعمل تلقائياً.
2. اذهب إلى تبويب **Actions** في مستودعك على GitHub.
3. ستجد عملية بناء بعنوان "Build Flutter APK".
4. عند اكتمال البناء (يتحول اللون للأخضر)، اضغط على اسم العملية.
5. انزل إلى قسم **Artifacts** وستجد ملف `haa-backup-release-apk` جاهزاً للتحميل.

## ملاحظات هامة:
- تم تحديث إصدار Flutter إلى **3.22.0** في ملف الـ Workflow لضمان التوافق.
- تم تحديث Gradle إلى **8.5** و Java إلى **17**.
- تم إضافة جميع الأذونات اللازمة (الكاميرا، التخزين، الإنترنت) في ملف `AndroidManifest.xml`.
