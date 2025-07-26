import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_notification_service.dart';

/// ويدجت عداد الإشعارات مع أيقونة
class NotificationBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double iconSize;

  const NotificationBadge({
    Key? key,
    this.onTap,
    this.iconColor,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = UserNotificationService();

    return StreamBuilder<int>(
      stream: notificationService.getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.data ?? 0;

        // في حالة الخطأ، اعرض رسالة في الكونسول
        if (snapshot.hasError) {
          print('خطأ في تحميل الإشعارات: ${snapshot.error}');
        }

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: iconColor ?? Colors.white,
                size: iconSize,
              ),
              onPressed: onTap,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// ويدجت عداد الإشعارات للأدمن
class AdminNotificationBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double iconSize;

  const AdminNotificationBadge({
    Key? key,
    this.onTap,
    this.iconColor,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = UserNotificationService();

    return StreamBuilder<int>(
      stream: notificationService.getAdminUnreadNotificationsCount(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.data ?? 0;

        // في حالة الخطأ، اعرض رسالة في الكونسول
        if (snapshot.hasError) {
          print('خطأ في تحميل إشعارات الأدمن: ${snapshot.error}');
        }

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.admin_panel_settings_outlined,
                color: iconColor ?? Colors.white,
                size: iconSize,
              ),
              onPressed: onTap,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// ويدجت عداد بسيط للاستخدام في أماكن أخرى
class SimpleBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color badgeColor;
  final Color textColor;

  const SimpleBadge({
    Key? key,
    required this.child,
    required this.count,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
