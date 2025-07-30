import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Bildirime tıklanınca ilgili harcamanın ID'sini tutacak global notifier
final ValueNotifier<int?> notificationTapExpenseId = ValueNotifier(null);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _setupTimeZone();
    await _initializeNotificationSettings();
  }

  // Check if exact alarms are permitted
  Future<bool> areExactAlarmsPermitted() async {
    try {
      // Try to schedule a test notification with exact alarm
      await _notificationsPlugin.zonedSchedule(
        999999, // Use a high ID to avoid conflicts
        'Test',
        'Test',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        const NotificationDetails(),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      // If successful, cancel the test notification
      await _notificationsPlugin.cancel(999999);
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        return false;
      }
      rethrow;
    }
  }

  // Request exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    try {
      // On Android 12+, users need to manually enable exact alarms in system settings
      // We can't programmatically request this permission, but we can guide the user
      debugPrint('Exact alarm permission needs to be enabled in system settings');
      return false;
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
      return false;
    }
  }

  Future<void> _setupTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> _initializeNotificationSettings() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_notification');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // iOS için bildirim işleme
      },
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında yapılacak işlemler
        _handleNotificationTap(response.payload);
      },
    );
  }

  void _handleNotificationTap(String? payload) {
    // Bildirim tıklandığında yapılacak işlemler
    // Örneğin: Belirli bir sayfaya yönlendirme
    debugPrint('Bildirim tıklandı: $payload');
    if (payload != null) {
      final id = int.tryParse(payload);
      if (id != null) {
        notificationTapExpenseId.value = id;
      }
    }
  }



  // Basit bildirim gönderme
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'main_channel',
      'Ana Bildirimler',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Zamanlanmış bildirim
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(time.hour, time.minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_channel', 
            'Günlük Hatırlatıcılar',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: false, // Inexact alarm kullan
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule daily notification: $e');
      // If all else fails, just show a simple notification
      await showTestNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  // Fallback method for inexact alarms
  Future<void> _scheduleInexactDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(time.hour, time.minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_channel', 
            'Günlük Hatırlatıcılar',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: false, // Use inexact alarm
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to schedule daily notification: $e');
      // If all else fails, just show a simple notification
      await showTestNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Her ay aynı gün ve saatte tekrar eden bildirim
  Future<void> scheduleMonthlyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'monthly_channel',
            'Aylık Hatırlatıcılar',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint('Exact alarms not permitted for monthly notification, using inexact alarm');
        await _scheduleInexactMonthlyNotification(
          id: id,
          title: title,
          body: body,
          date: date,
          time: time,
          payload: payload,
        );
      } else {
        rethrow;
      }
    }
  }

  // Fallback method for inexact monthly notifications
  Future<void> _scheduleInexactMonthlyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'monthly_channel',
            'Aylık Hatırlatıcılar',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: false, // Use inexact alarm
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule monthly notification: $e');
    }
  }

  // Tek seferlik bildirim
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime dateTime,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        dateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'one_time_channel',
            'Tek Seferlik Bildirimler',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint('Exact alarms not permitted for one-time notification, using inexact alarm');
        await _scheduleInexactOneTimeNotification(
          id: id,
          title: title,
          body: body,
          dateTime: dateTime,
          payload: payload,
        );
      } else {
        rethrow;
      }
    }
  }

  // Fallback method for inexact one-time notifications
  Future<void> _scheduleInexactOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime dateTime,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        dateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'one_time_channel',
            'Tek Seferlik Bildirimler',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: false, // Use inexact alarm
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule one-time notification: $e');
    }
  }

  // Haftalık tekrar eden bildirim
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday, // 1: Pazartesi, 7: Pazar
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      // Haftanın istenen gününe ayarla
      while (scheduledDate.weekday != weekday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_channel',
            'Haftalık Hatırlatıcılar',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint('Exact alarms not permitted for weekly notification, using inexact alarm');
        await _scheduleInexactWeeklyNotification(
          id: id,
          title: title,
          body: body,
          weekday: weekday,
          time: time,
          payload: payload,
        );
      } else {
        rethrow;
      }
    }
  }

  // Fallback method for inexact weekly notifications
  Future<void> _scheduleInexactWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      while (scheduledDate.weekday != weekday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_channel',
            'Haftalık Hatırlatıcılar',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: false, // Use inexact alarm
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule weekly notification: $e');
    }
  }

  // Yıllık tekrar eden bildirim
  Future<void> scheduleYearlyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'yearly_channel',
            'Yıllık Hatırlatıcılar',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint('Exact alarms not permitted for yearly notification, using inexact alarm');
        await _scheduleInexactYearlyNotification(
          id: id,
          title: title,
          body: body,
          date: date,
          time: time,
          payload: payload,
        );
      } else {
        rethrow;
      }
    }
  }

  // Fallback method for inexact yearly notifications
  Future<void> _scheduleInexactYearlyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'yearly_channel',
            'Yıllık Hatırlatıcılar',
            importance: Importance.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: false, // Use inexact alarm
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule yearly notification: $e');
    }
  }

  // Bildirimleri temizleme
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Belirli bir bildirimi iptal etme
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Hemen bildirim göster
  Future<void> showTestNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Bildirimleri',
          importance: Importance.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}