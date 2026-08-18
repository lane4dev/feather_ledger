import 'dart:async';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/notifications/reminder_schedule.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final recurringRemindersProvider = Provider<RecurringReminders>((ref) {
  final reminders = RecurringReminders(ref.read(recurringServiceProvider));
  ref.onDispose(reminders.dispose);
  return reminders;
});

/// Reconciles scheduled platform notifications with the pending bill table.
class RecurringReminders {
  RecurringReminders(this._service);
  final RecurringService _service;
  final _plugin = FlutterLocalNotificationsPlugin();
  StreamSubscription<List<ScheduledTransactionEntity>>? _subscription;
  Future<void> _queue = Future.value();
  bool _initialized = false;
  static const payloadPrefix = 'recurring-reminder:';
  static const postAction = 'post_bill';
  static const skipAction = 'skip_bill';
  static const _category = 'recurring_bill_actions';
  final _responsesChanged = StreamController<void>.broadcast();
  final _responses = <NotificationResponse>[];
  bool _autoPostDeferred = false;
  bool get hasPendingResponses => _responses.isNotEmpty;
  void deferAutoPostCatchUp() => _autoPostDeferred = true;
  bool takeDeferredAutoPostCatchUp() {
    final deferred = _autoPostDeferred;
    _autoPostDeferred = false;
    return deferred;
  }

  Stream<void> get responsesChanged => _responsesChanged.stream;

  List<NotificationResponse> takeResponses() {
    final pending = List<NotificationResponse>.of(_responses);
    _responses.clear();
    return pending;
  }

  void _receive(NotificationResponse response) {
    if (_responsesChanged.isClosed ||
        !(response.payload?.startsWith(payloadPrefix) ?? false)) {
      return;
    }
    if (_responses.any((r) =>
        r.payload == response.payload && r.actionId == response.actionId)) {
      return;
    }
    _responses.add(response);
    _responsesChanged.add(null);
  }

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize(
      {String postLabel = 'Post', String skipLabel = 'Skip'}) async {
    if (_initialized || !supported) return;
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
        InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            notificationCategories: [
              DarwinNotificationCategory(_category, actions: [
                DarwinNotificationAction.plain(postAction, postLabel,
                    options: {DarwinNotificationActionOption.foreground}),
                DarwinNotificationAction.plain(skipAction, skipLabel,
                    options: {DarwinNotificationActionOption.foreground}),
              ]),
            ],
          ),
        ),
        onDidReceiveNotificationResponse: _receive);
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse != null) {
      _receive(launch!.notificationResponse!);
    }
    _initialized = true;
  }

  Future<bool> requestPermission(
      {String postLabel = 'Post', String skipLabel = 'Skip'}) async {
    if (!supported) return false;
    await initialize(postLabel: postLabel, skipLabel: skipLabel);
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()!;
      if (await android.requestNotificationsPermission() == false) return false;
      if (await android.canScheduleExactNotifications() == false) {
        return await android.requestExactAlarmsPermission() == true;
      }
      return true;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()!
            .requestPermissions(alert: true, badge: false, sound: true) ==
        true;
  }

  Future<void> start(
      {required String title,
      required String channelName,
      String postLabel = 'Post',
      String skipLabel = 'Skip'}) async {
    if (!supported || _subscription != null) return;
    await initialize(postLabel: postLabel, skipLabel: skipLabel);
    _subscription = _service.watchScheduled().listen((items) {
      _queue = _queue
          .then((_) =>
              _reconcile(items, title, channelName, postLabel, skipLabel))
          .catchError((Object error) {
        debugPrint('Reminder synchronization failed: $error');
      });
    }, onError: (Object error) => debugPrint('Reminder watch failed: $error'));
  }

  Future<void> _reconcile(List<ScheduledTransactionEntity> items, String title,
      String channelName, String postLabel, String skipLabel) async {
    // iOS keeps at most 64 pending requests; reserve space for other uses.
    final desired = upcomingReminders(items, DateTime.now());
    final existing = await _plugin.pendingNotificationRequests();
    for (final notification in existing) {
      if (notification.payload?.startsWith(payloadPrefix) == true) {
        await _plugin.cancel(notification.id);
      }
    }
    final used = <int>{
      for (final notification in existing)
        if (notification.payload?.startsWith(payloadPrefix) != true)
          notification.id,
    };
    for (final item in desired) {
      var id = _stableId(item.id);
      while (!used.add(id)) {
        id = (id + 1) & 0x7fffffff;
      }
      final minutes = item.recurringTransactionSeries!.reminderMinutes!;
      await _plugin.zonedSchedule(
        id,
        title,
        item.recurringTransactionSeries!.description,
        tz.TZDateTime.from(
            item.date.subtract(Duration(minutes: minutes)), tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
              'recurring_reminders', channelName,
              importance: Importance.high,
              priority: Priority.high,
              actions: [
                AndroidNotificationAction(postAction, postLabel,
                    showsUserInterface: true),
                AndroidNotificationAction(skipAction, skipLabel,
                    showsUserInterface: true),
              ]),
          iOS: const DarwinNotificationDetails(categoryIdentifier: _category),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '$payloadPrefix${item.id}',
      );
    }
  }

  static int _stableId(String id) {
    var hash = 0x811c9dc5;
    for (final byte in id.codeUnits) {
      hash = ((hash ^ byte) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  void dispose() {
    _subscription?.cancel();
    _responsesChanged.close();
  }
}
