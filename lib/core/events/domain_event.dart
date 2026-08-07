abstract class DomainEvent {
  final String eventId;
  final DateTime timestamp;
  final String tenantId;
  final String branchId;
  final String performedBy;

  DomainEvent({
    required this.eventId,
    required this.timestamp,
    this.tenantId = 'TENANT_DEFAULT',
    this.branchId = 'BRANCH_MAIN',
    this.performedBy = 'Admin',
  });
}

class CustomerCreatedEvent extends DomainEvent {
  final String customerId;
  final String customerName;
  final String phone;

  CustomerCreatedEvent({
    required super.eventId,
    required super.timestamp,
    required this.customerId,
    required this.customerName,
    required this.phone,
    super.performedBy,
  });
}

class DeliveryCompletedEvent extends DomainEvent {
  final String deliveryId;
  final String orderId;
  final String customerId;
  final String employeeId;
  final int quantityDelivered;
  final int emptyCansReturned;
  final int damagedCansReported;
  final double amountCollected;

  DeliveryCompletedEvent({
    required super.eventId,
    required super.timestamp,
    required this.deliveryId,
    required this.orderId,
    required this.customerId,
    required this.employeeId,
    required this.quantityDelivered,
    required this.emptyCansReturned,
    required this.damagedCansReported,
    required this.amountCollected,
    super.performedBy,
  });
}

class PaymentCollectedEvent extends DomainEvent {
  final String paymentId;
  final String customerId;
  final double amount;
  final String paymentMode;

  PaymentCollectedEvent({
    required super.eventId,
    required super.timestamp,
    required this.paymentId,
    required this.customerId,
    required this.amount,
    required this.paymentMode,
    super.performedBy,
  });
}

class OrderStatusChangedEvent extends DomainEvent {
  final String orderId;
  final String newStatus;

  OrderStatusChangedEvent({
    required super.eventId,
    required super.timestamp,
    required this.orderId,
    required this.newStatus,
    super.performedBy,
  });
}

class InventoryUpdatedEvent extends DomainEvent {
  final int filledCans;
  final int emptyCans;
  final int damagedCans;
  final int customerBalanceCans;

  InventoryUpdatedEvent({
    required super.eventId,
    required super.timestamp,
    required this.filledCans,
    required this.emptyCans,
    required this.damagedCans,
    required this.customerBalanceCans,
    super.performedBy,
  });
}
