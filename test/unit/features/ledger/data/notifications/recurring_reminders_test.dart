import 'dart:async';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/data/notifications/recurring_reminders.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

class _Bills implements RecurringService {
  final controller = StreamController<List<ScheduledTransactionEntity>>();
  @override
  Stream<List<ScheduledTransactionEntity>> watchScheduled(
          {String? currencyCode}) =>
      controller.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('schedules and cancels reminders as pending bills change',
      (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    const timezone = MethodChannel('flutter_timezone');
    const notifications =
        MethodChannel('dexterous.com/flutter/local_notifications');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    final pending = <int, Map<String, Object?>>{};
    Map<Object?, Object?>? settings;
    messenger.setMockMethodCallHandler(timezone, (_) async => 'Asia/Shanghai');
    messenger.setMockMethodCallHandler(notifications, (call) async {
      switch (call.method) {
        case 'initialize':
          settings = Map<Object?, Object?>.from(call.arguments as Map);
          return true;
        case 'requestPermissions':
          return true;
        case 'getNotificationAppLaunchDetails':
          return {
            'notificationLaunchedApp': true,
            'notificationResponse': {
              'notificationId': 10,
              'notificationResponseType': 1,
              'payload': 'recurring-reminder:bill-1',
              'actionId': 'skip_bill',
            }
          };
        case 'pendingNotificationRequests':
          return pending.values.toList();
        case 'cancel':
          pending.remove(call.arguments as int);
          return null;
        case 'zonedSchedule':
          final values = Map<String, Object?>.from(call.arguments as Map);
          pending[values['id']! as int] = values;
          return null;
        default:
          throw StateError('Unexpected method ${call.method}');
      }
    });
    final bills = _Bills();
    final reminders = RecurringReminders(bills);
    addTearDown(() async {
      reminders.dispose();
      await bills.controller.close();
      messenger.setMockMethodCallHandler(timezone, null);
      messenger.setMockMethodCallHandler(notifications, null);
      debugDefaultTargetPlatformOverride = null;
    });
    final when = DateTime.now().add(const Duration(days: 3));
    final item = ScheduledTransactionEntity(
        id: 'bill-1',
        seriesId: 'series',
        occurrenceKey: scheduledOccurrenceKey(when),
        scheduledDate: when,
        recurringTransactionSeries: RecurringTransactionSeriesEntity(
            id: 'series',
            description: 'Rent',
            amountMinor: 100,
            type: RecurringSeriesKind.expense,
            categoryId: 'c',
            accountId: 'a',
            frequency: 'MONTHLY',
            startDate: when,
            autoPost: false,
            reminderMinutes: 15,
            mode: RecurringSeriesMode.repeating));
    await reminders.start(
        title: 'Upcoming transaction', channelName: 'Reminders');
    final categories = settings!['notificationCategories']! as List;
    final category = categories.single as Map;
    final actions = category['actions'] as List;
    expect(actions.map((action) => (action as Map)['identifier']),
        [RecurringReminders.postAction, RecurringReminders.skipAction]);
    expect(reminders.hasPendingResponses, isTrue);
    expect(reminders.takeResponses().single.actionId,
        RecurringReminders.skipAction);
    expect(reminders.hasPendingResponses, isFalse);
    bills.controller.add([item]);
    await tester.pumpAndSettle();
    expect(pending, hasLength(1));
    expect(
        (pending.values.single['platformSpecifics']!
            as Map)['categoryIdentifier'],
        'recurring_bill_actions');
    expect(pending.values.single['body'], 'Rent');
    expect(pending.values.single['payload'], 'recurring-reminder:bill-1');
    final oldSchedule = pending.values.single['scheduledDateTimeISO8601'];
    bills.controller
        .add([item.copyWith(dateOverride: when.add(const Duration(days: 1)))]);
    await tester.pumpAndSettle();
    expect(pending, hasLength(1));
    expect(
        pending.values.single['scheduledDateTimeISO8601'], isNot(oldSchedule));
    bills.controller
        .add([item.copyWith(status: ScheduledTransactionStatus.posted)]);
    await tester.pumpAndSettle();
    expect(pending, isEmpty);
    bills.controller.add([item]);
    await tester.pumpAndSettle();
    expect(pending, hasLength(1));
    bills.controller.add([]);
    await tester.pumpAndSettle();
    expect(pending, isEmpty, reason: 'removing bills cancels their reminders');
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets('Android reminders include foreground post and skip actions',
      (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    const timezone = MethodChannel('flutter_timezone');
    const notifications =
        MethodChannel('dexterous.com/flutter/local_notifications');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    Map<Object?, Object?>? scheduled;
    messenger.setMockMethodCallHandler(timezone, (_) async => 'Asia/Shanghai');
    messenger.setMockMethodCallHandler(notifications, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'getNotificationAppLaunchDetails':
          return {'notificationLaunchedApp': false};
        case 'pendingNotificationRequests':
          return <Map<String, Object?>>[];
        case 'zonedSchedule':
          scheduled = Map<Object?, Object?>.from(call.arguments as Map);
          return null;
        default:
          throw StateError('Unexpected method ${call.method}');
      }
    });
    final bills = _Bills();
    final reminders = RecurringReminders(bills);
    addTearDown(() async {
      reminders.dispose();
      await bills.controller.close();
      messenger.setMockMethodCallHandler(timezone, null);
      messenger.setMockMethodCallHandler(notifications, null);
      debugDefaultTargetPlatformOverride = null;
    });
    final when = DateTime.now().add(const Duration(days: 2));
    final item = ScheduledTransactionEntity(
        id: 'bill',
        seriesId: 's',
        occurrenceKey: scheduledOccurrenceKey(when),
        scheduledDate: when,
        recurringTransactionSeries: RecurringTransactionSeriesEntity(
            id: 's',
            description: 'Rent',
            amountMinor: 100,
            type: RecurringSeriesKind.expense,
            categoryId: 'c',
            accountId: 'a',
            frequency: 'MONTHLY',
            startDate: when,
            autoPost: false,
            reminderMinutes: 10,
            mode: RecurringSeriesMode.repeating));
    await reminders.start(
        title: 'Reminder',
        channelName: 'Reminders',
        postLabel: 'Post',
        skipLabel: 'Skip');
    bills.controller.add([item]);
    await tester.pumpAndSettle();
    final platform = scheduled!['platformSpecifics']! as Map;
    final actions = platform['actions'] as List;
    expect(actions.map((a) => (a as Map)['id']),
        [RecurringReminders.postAction, RecurringReminders.skipAction]);
    expect(
        actions.every((a) => (a as Map)['showsUserInterface'] == true), isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('only bills in the current currency schedule reminders',
      (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    const timezone = MethodChannel('flutter_timezone');
    const notifications =
        MethodChannel('dexterous.com/flutter/local_notifications');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    final pending = <int, Map<String, Object?>>{};
    messenger.setMockMethodCallHandler(timezone, (_) async => 'Asia/Shanghai');
    messenger.setMockMethodCallHandler(notifications, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'getNotificationAppLaunchDetails':
          return {'notificationLaunchedApp': false};
        case 'pendingNotificationRequests':
          return pending.values.toList();
        case 'cancel':
          pending.remove(call.arguments as int);
          return null;
        case 'zonedSchedule':
          final values = Map<String, Object?>.from(call.arguments as Map);
          pending[values['id']! as int] = values;
          return null;
        default:
          throw StateError('Unexpected method ${call.method}');
      }
    });
    final bills = _Bills();
    final reminders = RecurringReminders(bills, currencyCode: () => 'CNY');
    addTearDown(() async {
      reminders.dispose();
      await bills.controller.close();
      messenger.setMockMethodCallHandler(timezone, null);
      messenger.setMockMethodCallHandler(notifications, null);
      debugDefaultTargetPlatformOverride = null;
    });
    final when = DateTime.now().add(const Duration(days: 2));
    ScheduledTransactionEntity bill(String id, String currencyCode) =>
        ScheduledTransactionEntity(
            id: id,
            seriesId: 'series-$id',
            occurrenceKey: scheduledOccurrenceKey(when),
            scheduledDate: when,
            status: ScheduledTransactionStatus.scheduled,
            recurringTransactionSeries: RecurringTransactionSeriesEntity(
                id: 'series-$id',
                description: 'Rent',
                amountMinor: 100,
                type: RecurringSeriesKind.expense,
                categoryId: 'c',
                accountId: 'a',
                frequency: 'MONTHLY',
                startDate: when,
                autoPost: false,
                reminderMinutes: 30,
                mode: RecurringSeriesMode.repeating),
            account: AccountEntity(
                id: 'a',
                name: 'Cash',
                type: AccountType.cash,
                currencyCode: currencyCode,
                balanceMinor: 0,
                archived: false,
                lastUpdatedEventId: 0));
    await reminders.start(
        title: 'Upcoming transaction', channelName: 'Reminders');
    bills.controller.add([
      bill('cny', 'CNY'),
      bill('usd', 'USD'),
    ]);
    await tester.pumpAndSettle();
    expect(pending, hasLength(1));
    expect(pending.values.single['payload'], 'recurring-reminder:cny');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      'enforces the 60-notification platform cap when a high-frequency daily series materializes >60 upcoming bills',
      (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    const timezone = MethodChannel('flutter_timezone');
    const notifications =
        MethodChannel('dexterous.com/flutter/local_notifications');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    final pending = <int, Map<String, Object?>>{};
    messenger.setMockMethodCallHandler(timezone, (_) async => 'Asia/Shanghai');
    messenger.setMockMethodCallHandler(notifications, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'getNotificationAppLaunchDetails':
          return {'notificationLaunchedApp': false};
        case 'pendingNotificationRequests':
          return pending.values.toList();
        case 'cancel':
          pending.remove(call.arguments as int);
          return null;
        case 'zonedSchedule':
          final values = Map<String, Object?>.from(call.arguments as Map);
          pending[values['id']! as int] = values;
          return null;
        default:
          throw StateError('Unexpected method ${call.method}');
      }
    });
    final bills = _Bills();
    final reminders = RecurringReminders(bills);
    addTearDown(() async {
      reminders.dispose();
      await bills.controller.close();
      messenger.setMockMethodCallHandler(timezone, null);
      messenger.setMockMethodCallHandler(notifications, null);
      debugDefaultTargetPlatformOverride = null;
    });

    final start = DateTime.now().add(const Duration(days: 1));
    final series = RecurringTransactionSeriesEntity(
      id: 'daily-series',
      description: 'Daily Commute',
      amountMinor: 500,
      type: RecurringSeriesKind.expense,
      categoryId: 'c',
      accountId: 'a',
      frequency: 'DAILY',
      startDate: start,
      autoPost: false,
      reminderMinutes: 15,
      mode: RecurringSeriesMode.repeating,
    );
    // 85 materialized daily bills (covering 3 full calendar months).
    final manyBills = List.generate(85, (i) {
      final date = DateTime(start.year, start.month, start.day + i, 9, 0);
      return ScheduledTransactionEntity(
        id: 'daily-${i.toString().padLeft(3, '0')}',
        seriesId: 'daily-series',
        occurrenceKey: scheduledOccurrenceKey(date),
        scheduledDate: date,
        status: ScheduledTransactionStatus.scheduled,
        recurringTransactionSeries: series,
      );
    });

    await reminders.start(
      title: 'Upcoming transaction',
      channelName: 'Reminders',
    );
    bills.controller.add(manyBills.reversed.toList());
    await tester.pumpAndSettle();

    expect(pending, hasLength(60),
        reason: 'platform queue cap of 60 reminders must still hold');
    final payloads = pending.values.map((v) => v['payload'] as String).toSet();
    expect(payloads, contains('recurring-reminder:daily-000'));
    expect(payloads, contains('recurring-reminder:daily-059'));
    expect(payloads, isNot(contains('recurring-reminder:daily-060')));
    debugDefaultTargetPlatformOverride = null;
  });
}
