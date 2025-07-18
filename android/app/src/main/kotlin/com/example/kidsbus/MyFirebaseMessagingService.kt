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
import io.flutter.embedding.android.FlutterActivity

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "MyFirebaseMsgService"
        private const val CHANNEL_ID = "mybus_notifications"
        private const val NOTIFICATION_ID = 1
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "From: ${remoteMessage.from}")

        // التحقق من وجود بيانات في الرسالة
        if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "Message data payload: ${remoteMessage.data}")
        }

        // التحقق من وجود إشعار في الرسالة
        remoteMessage.notification?.let {
            Log.d(TAG, "Message Notification Body: ${it.body}")
            sendNotification(it.title ?: "إشعار جديد", it.body ?: "", remoteMessage.data)
        }

        // إذا لم يكن هناك notification payload، أنشئ إشعار من البيانات
        if (remoteMessage.notification == null && remoteMessage.data.isNotEmpty()) {
            val title = remoteMessage.data["title"] ?: "إشعار جديد"
            val body = remoteMessage.data["body"] ?: "لديك إشعار جديد"
            sendNotification(title, body, remoteMessage.data)
        }
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
        // إنشاء Intent لفتح التطبيق
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            // إضافة البيانات للـ Intent
            data.forEach { (key, value) ->
                putExtra(key, value)
            }
        }

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_ONE_SHOT
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, pendingIntentFlags
        )

        // إعداد الصوت
        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        // إنشاء الإشعار
        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(messageBody)
            .setAutoCancel(true)
            .setSound(defaultSoundUri)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVibrate(longArrayOf(1000, 1000, 1000, 1000, 1000))
            .setLights(0xFFFF6B6B.toInt(), 3000, 3000)
            .setStyle(NotificationCompat.BigTextStyle().bigText(messageBody))

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // إنشاء قناة الإشعارات لـ Android O والأحدث
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel(notificationManager)
        }

        // عرض الإشعار
        val notificationId = System.currentTimeMillis().toInt()
        notificationManager.notify(notificationId, notificationBuilder.build())

        Log.d(TAG, "Notification sent: $title - $messageBody")
    }

    private fun createNotificationChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "إشعارات MyBus",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "إشعارات عامة لتطبيق MyBus"
                enableLights(true)
                lightColor = 0xFFFF6B6B.toInt()
                enableVibration(true)
                vibrationPattern = longArrayOf(1000, 1000, 1000, 1000, 1000)
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    null
                )
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)

            // إنشاء قنوات إضافية
            createAdditionalChannels(notificationManager)
        }
    }

    private fun createAdditionalChannels(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channels = listOf(
                NotificationChannel(
                    "student_notifications",
                    "إشعارات الطلاب",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "إشعارات متعلقة بالطلاب وأنشطتهم"
                    enableLights(true)
                    lightColor = 0xFF4CAF50.toInt()
                    enableVibration(true)
                    setShowBadge(true)
                },
                NotificationChannel(
                    "bus_notifications",
                    "إشعارات الباص",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "إشعارات ركوب ونزول الباص"
                    enableLights(true)
                    lightColor = 0xFF2196F3.toInt()
                    enableVibration(true)
                    setShowBadge(true)
                },
                NotificationChannel(
                    "emergency_notifications",
                    "تنبيهات الطوارئ",
                    NotificationManager.IMPORTANCE_MAX
                ).apply {
                    description = "تنبيهات طوارئ مهمة وعاجلة"
                    enableLights(true)
                    lightColor = 0xFFF44336.toInt()
                    enableVibration(true)
                    vibrationPattern = longArrayOf(100, 200, 300, 400, 500, 400, 300, 200, 400)
                    setShowBadge(true)
                }
            )

            channels.forEach { channel ->
                notificationManager.createNotificationChannel(channel)
            }
        }
    }
}
