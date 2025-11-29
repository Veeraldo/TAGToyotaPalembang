import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Service untuk mengelola notifikasi otomatis
class BackgroundNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Inisialisasi notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // Request permissions menggunakan flutter_local_notifications
    await _requestPermissions();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // Create notification channel
    const androidChannel = AndroidNotificationChannel(
      'birthday_reminders',
      'Birthday Reminders',
      description: 'Notifikasi pengingat ulang tahun customer',
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    print('Notification service initialized');
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Request notification permission (Android 13+)
      final granted = await androidImplementation.requestNotificationsPermission();
      print('Notification permission granted: $granted');

      // Request exact alarm permission (Android 12+)
      final exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
      print('Exact alarm permission granted: $exactAlarmGranted');
    }

    // Request iOS permissions
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> registerPeriodicTask() async {
    await initialize();
    await _scheduleDailyNotifications();
    print('Daily notifications scheduled');
  }

  static Future<void> _scheduleDailyNotifications() async {
    try {
      await _notifications.cancelAll();

      // Schedule untuk besok jam 8 pagi
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        8, 
        0,
      );

      // Jika sudah lewat jam 8 hari ini, schedule untuk besok
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await checkBirthdayReminders();

      print('Next check scheduled at: $scheduledDate');
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  /// Cek birthday reminders sekarang
  static Future<void> checkBirthdayReminders() async {
    await _checkBirthdayReminders();
  }

  /// Test manual check (untuk development)
  static Future<void> testManualCheck() async {
    await initialize();
    await _checkBirthdayReminders();
  }

  /// Cancel all notifications
  static Future<void> cancelAllTasks() async {
    await _notifications.cancelAll();
    print('All notifications cancelled');
  }
}

Future<void> _checkBirthdayReminders() async {
  try {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();


    final today = DateTime(now.year, now.month, now.day);

    final customersSnapshot = await db.collection('customers').get();

    final reminders = {
      'sevenDays': <String>[],
      'threeDays': <String>[],
      'today': <String>[],
    };

    print('Birthday Check Started');
    print('Today: ${today.day}/${today.month}/${today.year}');
    print('Checking ${customersSnapshot.docs.length} customers...\n');

    for (var doc in customersSnapshot.docs) {
      final customer = doc.data();
      final tanggalLahir = customer['Tanggal_Lahir'];
      final customerName = customer['Customer_Name'] ?? 'Customer';

      if (tanggalLahir == null) continue;

      try {
        final parts = tanggalLahir.toString().split('/');
        if (parts.length != 3) continue;

        final first = int.parse(parts[0]);
        final second = int.parse(parts[1]);

        int birthDay, birthMonth;
        if (first > 12) {
          birthDay = first;
          birthMonth = second;
        } else {
          birthDay = first;
          birthMonth = second;
        }

        if (birthDay < 1 ||
            birthDay > 31 ||
            birthMonth < 1 ||
            birthMonth > 12) {
          continue;
        }

        // Ulang tahun tahun ini
        var nextBirthday = DateTime(today.year, birthMonth, birthDay);

        // Kalau ulangtahun lewat tahun ini, set ke tahun depan
        if (nextBirthday.isBefore(today)) {
          nextBirthday = DateTime(today.year + 1, birthMonth, birthDay);
        }

        final diffDays = nextBirthday.difference(today).inDays;

        print('Customer: $customerName');
        print('  Birthday: $birthDay/$birthMonth');
        print(
          '  Next Birthday: ${nextBirthday.day}/${nextBirthday.month}/${nextBirthday.year}',
        );
        print('  Days until birthday: $diffDays\n');

        if (diffDays == 7) {
          reminders['sevenDays']!.add(customerName);
        } else if (diffDays == 3) {
          reminders['threeDays']!.add(customerName);
        } else if (diffDays == 0) {
          reminders['today']!.add(customerName);
        }
      } catch (e) {
        print('Error processing customer $customerName: $e\n');
      }
    }

    print('Summary');
    print('7 Days: ${reminders['sevenDays']!.length} customers');
    print('3 Days: ${reminders['threeDays']!.length} customers');
    print('Today: ${reminders['today']!.length} customers\n');

    // Setup notification details
    const androidDetails = AndroidNotificationDetails(
      'birthday_reminders',
      'Birthday Reminders',
      channelDescription: 'Notifikasi pengingat ulang tahun customer',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final notifications = BackgroundNotificationService._notifications;

    if (reminders['sevenDays']!.isNotEmpty) {
      final names = reminders['sevenDays']!.join(', ');
      await notifications.show(
        1,
        '🎂 Pengingat Ulang Tahun (7 Hari Lagi)',
        '$names akan berulang tahun 7 hari lagi!',
        notificationDetails,
      );
      print('✓ Notification sent: 7 days reminder for $names');
    }

    if (reminders['threeDays']!.isNotEmpty) {
      final names = reminders['threeDays']!.join(', ');
      await notifications.show(
        2,
        '🎂 Pengingat Ulang Tahun (3 Hari Lagi)',
        '$names akan berulang tahun 3 hari lagi!',
        notificationDetails,
      );
      print('✓ Notification sent: 3 days reminder for $names');
    }

    if (reminders['today']!.isNotEmpty) {
      final names = reminders['today']!.join(', ');
      await notifications.show(
        3,
        '🎉 Hari Ulang Tahun!',
        'Hari ini $names berulang tahun! 🎈🎉',
        notificationDetails,
      );
      print('✓ Notification sent: Birthday today for $names');
    }

    print('\n=== Birthday Check Completed ===\n');
  } catch (e) {
    print('Error in _checkBirthdayReminders: $e');
  }
}
