import 'package:event_bus/event_bus.dart';

class EventBusUtil {
  static final EventBusUtil _instance = EventBusUtil._internal();
  factory EventBusUtil() => _instance;
  EventBusUtil._internal();

  final EventBus _eventBus = EventBus();

  EventBus get eventBus => _eventBus;
}