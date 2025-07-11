# MyBus Admin Web Dashboard

لوحة تحكم ويب احترافية لإدارة نظام MyBus للنقل المدرسي.

## المميزات

### 🎯 **واجهة احترافية**
- تصميم حديث ومتجاوب
- دعم كامل للغة العربية (RTL)
- ألوان وتأثيرات بصرية جذابة
- تجربة مستخدم محسنة

### 📊 **لوحة التحكم الرئيسية**
- إحصائيات شاملة ومباشرة
- رسوم بيانية تفاعلية
- مراقبة الأنشطة في الوقت الفعلي
- تقارير مرئية

### 👥 **إدارة المستخدمين**
- إدارة الطلاب (إضافة، تعديل، حذف)
- إدارة المشرفين
- إدارة أولياء الأمور
- تتبع حالة المستخدمين

### 📈 **التقارير والإحصائيات**
- تقارير الحضور
- إحصائيات استخدام الحافلات
- تصدير التقارير (Excel, PDF)
- تحليلات مفصلة

### ⚙️ **الإعدادات**
- إعدادات النظام العامة
- إدارة الإشعارات
- النسخ الاحتياطية
- إعدادات الأمان

## التقنيات المستخدمة

### 🎨 **Frontend**
- **HTML5** - هيكل الصفحات
- **CSS3** - التصميم والتنسيق
- **Bootstrap 5** - إطار العمل للتصميم المتجاوب
- **JavaScript ES6+** - البرمجة التفاعلية
- **Chart.js** - الرسوم البيانية
- **Font Awesome** - الأيقونات

### 🔥 **Backend & Database**
- **Firebase Authentication** - نظام المصادقة
- **Cloud Firestore** - قاعدة البيانات
- **Firebase Hosting** - الاستضافة
- **Real-time Updates** - التحديثات المباشرة

## التثبيت والتشغيل

### 1. **متطلبات النظام**
- متصفح ويب حديث (Chrome, Firefox, Safari, Edge)
- اتصال بالإنترنت
- حساب Firebase مُعد مسبقاً

### 2. **إعداد المشروع**
```bash
# نسخ الملفات إلى خادم الويب
cp -r web_admin/* /var/www/html/admin/

# أو تشغيل خادم محلي
cd web_admin
python -m http.server 8080
```

### 3. **الوصول للوحة التحكم**
- افتح المتصفح واذهب إلى: `http://localhost:8080`
- أو `http://your-domain.com/admin`

### 4. **تسجيل الدخول**
- **البريد الإلكتروني**: `admin@mybus.com`
- **كلمة المرور**: `admin123456`

## هيكل المشروع

```
web_admin/
├── index.html          # الصفحة الرئيسية
├── styles.css          # ملف التصميم
├── app.js             # الوظائف الرئيسية
├── firebase-config.js  # إعدادات Firebase
└── README.md          # هذا الملف
```

## الصفحات والوظائف

### 🏠 **الصفحة الرئيسية (Dashboard)**
- إحصائيات سريعة
- رسوم بيانية للطلاب والمستخدمين
- آخر الأنشطة
- نظرة عامة على النظام

### 🎓 **إدارة الطلاب**
- عرض قائمة جميع الطلاب
- إضافة طالب جديد
- تعديل بيانات الطلاب
- حذف الطلاب
- البحث والفلترة

### 👨‍💼 **إدارة المشرفين**
- عرض قائمة المشرفين
- إضافة مشرف جديد
- إدارة صلاحيات المشرفين
- تتبع أنشطة المشرفين

### 👨‍👩‍👧‍👦 **إدارة أولياء الأمور**
- عرض قائمة أولياء الأمور
- ربط الأطفال بأولياء الأمور
- إدارة الاتصالات
- تتبع التفاعل

### 📊 **التقارير**
- تقارير الحضور الشهرية
- إحصائيات استخدام الحافلات
- تصدير البيانات
- تحليلات مخصصة

### ⚙️ **الإعدادات**
- إعدادات المؤسسة
- إعدادات الإشعارات
- إدارة النسخ الاحتياطية
- إعدادات الأمان

## الأمان والحماية

### 🔐 **المصادقة**
- تسجيل دخول آمن عبر Firebase
- التحقق من صلاحيات الأدمن
- جلسات آمنة
- تسجيل خروج تلقائي

### 🛡️ **الحماية**
- تشفير البيانات
- قواعد أمان Firestore
- حماية من الوصول غير المصرح
- تسجيل العمليات

## التخصيص والتطوير

### 🎨 **تخصيص التصميم**
- تعديل الألوان في `styles.css`
- إضافة شعار المؤسسة
- تخصيص الخطوط
- تعديل التخطيط

### 🔧 **إضافة وظائف جديدة**
- إضافة صفحات جديدة في `app.js`
- تطوير وظائف Firebase في `firebase-config.js`
- إضافة رسوم بيانية جديدة
- تطوير التقارير

## الدعم والمساعدة

### 📞 **التواصل**
- البريد الإلكتروني: `support@mybus.com`
- الهاتف: `+966501234567`

### 📚 **الموارد**
- [Firebase Documentation](https://firebase.google.com/docs)
- [Bootstrap Documentation](https://getbootstrap.com/docs)
- [Chart.js Documentation](https://www.chartjs.org/docs)

## الترخيص

هذا المشروع مرخص تحت رخصة MIT. راجع ملف LICENSE للمزيد من التفاصيل.

---

**تم تطوير هذه اللوحة خصيصاً لنظام MyBus للنقل المدرسي**

**مع أطيب التمنيات بالنجاح! 🚀**
