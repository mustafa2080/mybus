# 🔥 إعداد Firebase للإشعارات

## 📋 **الخطوات المطلوبة:**

### 1. **إنشاء الفهارس في Firestore**

قم بتشغيل الأمر التالي لإنشاء الفهارس المطلوبة:

```bash
firebase deploy --only firestore:indexes
```

أو قم بإنشاء الفهارس يدوياً من خلال:
- انتقل إلى [Firebase Console](https://console.firebase.google.com)
- اختر مشروعك `mybus-5a992`
- انتقل إلى Firestore Database > Indexes
- أضف الفهارس التالية:

#### **فهرس 1: الإشعارات غير المقروءة**
```
Collection: notifications
Fields:
- recipientId (Ascending)
- isRead (Ascending)
- createdAt (Descending)
```

#### **فهرس 2: إشعارات الأدمن**
```
Collection: notifications
Fields:
- type (Ascending)
- isRead (Ascending)
- createdAt (Descending)
```

#### **فهرس 3: الإشعارات حسب المستلم**
```
Collection: notifications
Fields:
- recipientId (Ascending)
- createdAt (Descending)
```

### 2. **رفع ملفات الصوت**

1. أضف ملفات الصوت في مجلد `assets/sounds/`:
   - `notification.mp3` - صوت الإشعار العادي
   - `urgent.mp3` - صوت الإشعار العاجل
   - `success.mp3` - صوت النجاح

2. تأكد من تحديث `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/sounds/
```

### 3. **إعداد Firebase Cloud Messaging (FCM)**

1. انتقل إلى Firebase Console > Project Settings
2. في تبويب Cloud Messaging، احصل على Server Key
3. أضف Server Key في إعدادات التطبيق

### 4. **نشر Cloud Functions (اختياري)**

إذا كنت تستخدم Cloud Functions للإشعارات:

```bash
cd functions
npm install
firebase deploy --only functions
```

### 5. **اختبار النظام**

1. شغل التطبيق:
```bash
flutter run
```

2. اختبر الإشعارات من خلال:
   - إنشاء شكوى جديدة
   - إضافة طالب جديد
   - تسجيل غياب

### 6. **مراقبة الأخطاء**

راقب الأخطاء في:
- Firebase Console > Firestore > Usage
- Flutter Debug Console
- Firebase Functions Logs (إذا كنت تستخدمها)

## 🔧 **حل المشاكل الشائعة:**

### خطأ "Query requires an index"
- تأكد من إنشاء جميع الفهارس المطلوبة
- انتظر بضع دقائق بعد إنشاء الفهرس

### الإشعارات لا تظهر
- تحقق من أذونات الإشعارات في الجهاز
- تأكد من تهيئة FCM بشكل صحيح

### عداد الإشعارات لا يعمل
- تحقق من قواعد Firestore Security Rules
- تأكد من صحة استعلامات Firestore

## 📱 **الاستخدام:**

بعد إكمال الإعداد، ستعمل الميزات التالية:

✅ **عداد الإشعارات في الشريط العلوي**
✅ **إشعارات فورية للأحداث المهمة**
✅ **أصوات مخصصة للإشعارات**
✅ **تصنيف الإشعارات حسب الأولوية**
✅ **إشعارات خاصة للأدمن**

## 🎯 **النتيجة المتوقعة:**

- عداد أحمر يظهر عدد الإشعارات غير المقروءة
- إشعارات فورية عند حدوث أحداث مهمة
- أصوات مميزة لكل نوع إشعار
- واجهة سهلة لإدارة الإشعارات
