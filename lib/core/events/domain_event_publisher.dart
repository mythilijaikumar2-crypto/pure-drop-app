import 'dart:async';
import 'domain_event.dart';

typedef DomainEventListener<T extends DomainEvent> = void Function(T event);

class DomainEventPublisher {
  static final DomainEventPublisher _instance = DomainEventPublisher._internal();
  factory DomainEventPublisher() => _instance;
  DomainEventPublisher._internal();

  final _controller = StreamController<DomainEvent>.broadcast();

  Stream<DomainEvent> get eventStream => _controller.stream;

  void publish(DomainEvent event) {
    _controller.add(event);
  }

  StreamSubscription<T> subscribe<T extends DomainEvent>(void Function(T event) onData) {
    return _controller.stream.where((e) => e is T).cast<T>().listen(onData);
  }
}
