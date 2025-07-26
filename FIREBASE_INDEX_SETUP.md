# 🔥 إعداد فهارس Firebase للإشعارات

## 📋 **الخطوات المطلوبة فوراً:**

### 1. **إنشاء الفهرس الأساسي**

انتقل إلى: https://console.firebase.google.com/v1/r/project/mybus-5a992/firestore/indexes

أو:
1. افتح [Firebase Console](https://console.firebase.google.com)
2. اختر مشروع `mybus-5a992`
3. انتقل إلى **Firestore Database**
4. اختر تبويب **Indexes**
5. انقر **Create Index**

### 2. **إضافة الفهارس التالية:**

#### **فهرس 1: الإشعارات حسب المستلم والتاريخ**
```
Collection ID: notifications
Fields:
- recipientId: Ascending
- createdAt: Descending
```

#### **فهرس 2: الإشعارات غير المقروءة**
```
Collection ID: notifications
Fields:
- recipientId: Ascending
- isRead: Ascending
- createdAt: Descending
```

#### **فهرس 3: إشعارات الأدمن**
```
Collection ID: notifications
Fields:
- type: Ascending
- isRead: Ascending
- createdAt: Descending
```

### 3. **أو استخدم Firebase CLI:**

```bash
firebase deploy --only firestore:indexes
```

### 4. **انتظار إنشاء الفهارس:**
- قد يستغرق الأمر بضع دقائق
- ستحصل على إشعار عند اكتمال الإنشاء

## ⚠️ **مهم:**
بعد إنشاء الفهارس، أعد تشغيل التطبيق:
```bash
flutter hot restart
```
