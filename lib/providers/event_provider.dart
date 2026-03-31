import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:study_app/database/hive_service.dart';
import 'package:study_app/models/event.dart';

import 'package:study_app/services/notification_service.dart';

class EventProvider extends ChangeNotifier {
  Box<Event> get _eventsBox => HiveService.eventsBox;

  List<Event> get events {
    try {
      final list = _eventsBox.values.whereType<Event>().toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    } catch (e) {
      debugPrint('Error getting events: $e');
      return [];
    }
  }

  Future<void> addEvent(Event event) async {
    try {
      await _eventsBox.put(event.id, event);
    } catch (e) {
      debugPrint('EventProvider.addEvent box error: $e');
      return;
    }
    // Fire-and-forget: notification failure must NEVER block the UI update
    try {
      NotificationService().scheduleEventNotification(event);
    } catch (e) {
      debugPrint('EventProvider.addEvent notification error (non-fatal): $e');
    }
    notifyListeners();
  }

  Future<void> deleteEvent(String id) async {
    await _eventsBox.delete(id);
    NotificationService().cancelNotifications(id);
    notifyListeners();
  }

  Future<void> toggleStatus(String id) async {
    final event = _eventsBox.get(id);
    if (event != null) {
      event.isCompleted = !event.isCompleted;
      await event.save();
      notifyListeners();
    }
  }

  List<Event> get upcomingEvents {
    // Return all non-completed events
    return events.where((e) => !e.isCompleted).toList();
  }
}
