package com.example.kidsbus

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "MyFirebaseMsgService"
        private const val CHANNEL_ID = "mybus_notifications"
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "📱 FCM Message received from: ${remoteMessage.from}")
        Log.d(TAG, "📱 Message ID: ${remoteMessage.messageId}")

        // طباعة جميع البيانات للتشخيص
        if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "📱 Message data payload: ${remoteMessage.data}")
        }

        // متغيرات العنوان والمحتوى
        var title = "إشعار جديد"
        var body = "لديك إشعار جديد"

        // أولوية للـ notification payload إذا كان موجود
        remoteMessage.notification?.let { notification ->
            Log.d(TAG, "📱 Notification payload found")
            title = notification.title ?: title
            body = notification.body ?: body
        }

        // إذا لم يكن هناك notification payload، استخدم البيانات
        if (remoteMessage.notification == null && remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "📱 No notification payload, using data")
            title = remoteMessage.data["title"] ?: title
            body = remoteMessage.data["body"] ?: body
        }

        // إرسال الإشعار في جميع الحالات
        Log.d(TAG, "📱 Sending notification: $title - $body")
        sendNotification(title, body, remoteMessage.data)
    }

    override fun onNewToken(token: String) {
        Log.d(TAG, "Refreshed token: $token")
        // يمكن إرسال التوكن للخادم هنا
        sendRegistrationToServer(token)
    }

    private fun sendRegistrationToServer(token: String?) {
        // TODO: تنفيذ إرسال التوكن للخادم
        Log.d(TAG, "sendRegistrationTokenToServer($token)")
    }

    private fun sendNotification(title: String, messageBody: String, data: Map<String, String>) {
        Log.d(TAG, "🔔 Creating notification: $title")

        try {
            // إنشاء Intent لفتح التطبيق
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)

            // إضافة البيانات للـ Intent
            for ((key, value) in data) {
                intent.putExtra(key, value)
            }

            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_ONE_SHOT
            }

            val pendingIntent = PendingIntent.getActivity(this, 0, intent, pendingIntentFlags)

            // إعداد الصوت
            val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            // تحديد قناة الإشعار حسب النوع
            val channelId = data["channelId"] ?: CHANNEL_ID

            // إنشاء الإشعار مع جميع الخصائص
            val notificationBuilder = NotificationCompat.Builder(this, channelId)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(title)
                .setContentText(messageBody)
                .setAutoCancel(true)
                .setSound(defaultSoundUri)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setVibrate(longArrayOf(0, 1000, 500, 1000))
                .setLights(android.graphics.Color.parseColor("#FF6B6B"), 3000, 3000)
                .setStyle(NotificationCompat.BigTextStyle().bigText(messageBody))
                .setShowWhen(true)
                .setWhen(System.currentTimeMillis())
                .setOnlyAlertOnce(false)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // إنشاء قناة الإشعارات لـ Android O والأحدث
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                createNotificationChannel(notificationManager)
            }

            // عرض الإشعار مع ID فريد
            val notificationId = System.currentTimeMillis().toInt()
            notificationManager.notify(notificationId, notificationBuilder.build())

            Log.d(TAG, "✅ Notification displayed successfully: $title")

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error creating notification: ${e.message}", e)
        }
    }

    private fun createNotificationChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d(TAG, "🔧 Creating notification channels...")

            // القناة الرئيسية
            val mainChannel = NotificationChannel(
                CHANNEL_ID,
                "إشعارات MyBus",
                NotificationManager.IMPORTANCE_HIGH
            )
            mainChannel.description = "إشعارات عامة لتطبيق MyBus"
            mainChannel.enableLights(true)
            mainChannel.lightColor = android.graphics.Color.parseColor("#FF6B6B")
            mainChannel.enableVibration(true)
            mainChannel.vibrationPattern = longArrayOf(0, 1000, 500, 1000)
            mainChannel.setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                null
            )
            mainChannel.setShowBadge(true)
            mainChannel.lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            mainChannel.setBypassDnd(false)

            notificationManager.createNotificationChannel(mainChannel)

            // قنوات إضافية
            val studentChannel = NotificationChannel(
                "student_notifications",
                "إشعارات الطلاب",
                NotificationManager.IMPORTANCE_HIGH
            )
            studentChannel.description = "إشعارات متعلقة بالطلاب"
            studentChannel.enableVibration(true)
            studentChannel.setShowBadge(true)

            val busChannel = NotificationChannel(
                "bus_notifications",
                "إشعارات الباص",
                NotificationManager.IMPORTANCE_HIGH
            )
            busChannel.description = "إشعارات الباص والرحلات"
            busChannel.enableVibration(true)
            busChannel.setShowBadge(true)

            val emergencyChannel = NotificationChannel(
                "emergency_notifications",
                "تنبيهات الطوارئ",
                NotificationManager.IMPORTANCE_MAX
            )
            emergencyChannel.description = "تنبيهات طوارئ مهمة"
            emergencyChannel.enableVibration(true)
            emergencyChannel.setShowBadge(true)
            emergencyChannel.setBypassDnd(true)

            notificationManager.createNotificationChannel(studentChannel)
            notificationManager.createNotificationChannel(busChannel)
            notificationManager.createNotificationChannel(emergencyChannel)

            Log.d(TAG, "✅ Notification channels created successfully")
        }
    }

}
