const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./mybus-5a992-firebase-adminsdk-ixqhj-b8b8b8b8b8.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'mybus-5a992'
});

const auth = admin.auth();
const firestore = admin.firestore();

async function createAdminUser() {
  try {
    console.log('🚀 إنشاء المستخدم الأدمن...');
    
    const adminEmail = 'admin@mybus.com';
    const adminPassword = 'admin123456';
    
    // إنشاء المستخدم في Firebase Auth
    const userRecord = await auth.createUser({
      email: adminEmail,
      password: adminPassword,
      displayName: 'مدير النظام'
    });
    
    console.log('✅ تم إنشاء المستخدم في Auth:', userRecord.uid);
    
    // إضافة بيانات المستخدم في Firestore
    await firestore.collection('users').doc(userRecord.uid).set({
      id: userRecord.uid,
      email: adminEmail,
      name: 'مدير النظام',
      phone: '0501234567',
      userType: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ تم إضافة بيانات المستخدم في Firestore');
    console.log('📧 البريد الإلكتروني:', adminEmail);
    console.log('🔑 كلمة المرور:', adminPassword);
    
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('👤 المستخدم الأدمن موجود بالفعل');
    } else {
      console.error('❌ خطأ في إنشاء المستخدم:', error);
    }
  }
}

async function createSupervisorUser() {
  try {
    console.log('🚀 إنشاء المستخدم المشرف...');
    
    const supervisorEmail = 'supervisor@mybus.com';
    const supervisorPassword = 'supervisor123456';
    
    // إنشاء المستخدم في Firebase Auth
    const userRecord = await auth.createUser({
      email: supervisorEmail,
      password: supervisorPassword,
      displayName: 'أحمد المشرف'
    });
    
    console.log('✅ تم إنشاء المشرف في Auth:', userRecord.uid);
    
    // إضافة بيانات المستخدم في Firestore
    await firestore.collection('users').doc(userRecord.uid).set({
      id: userRecord.uid,
      email: supervisorEmail,
      name: 'أحمد المشرف',
      phone: '0507654321',
      userType: 'supervisor',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ تم إضافة بيانات المشرف في Firestore');
    console.log('📧 البريد الإلكتروني:', supervisorEmail);
    console.log('🔑 كلمة المرور:', supervisorPassword);
    
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('👨‍🏫 المستخدم المشرف موجود بالفعل');
    } else {
      console.error('❌ خطأ في إنشاء المشرف:', error);
    }
  }
}

async function main() {
  await createAdminUser();
  await createSupervisorUser();
  console.log('🎉 تم الانتهاء من إنشاء المستخدمين!');
  process.exit(0);
}

main().catch(console.error);
