import '../notification_service.dart';

class NotificationAutomation {
  final NotificationService _notificationService = NotificationService();

  Future<void> triggerLowStockAlert(int remainingCans) async {
    await _notificationService.showNotification(
      id: 101,
      title: '⚠️ Low Water Stock Alert',
      body: 'Filled cans stock is low ($remainingCans cans remaining). Please order water purchase.',
    );
  }

  Future<void> triggerOrderAssignedAlert(String orderId, String driverName) async {
    await _notificationService.showNotification(
      id: 102,
      title: '🚚 Delivery Order Assigned',
      body: 'Order #$orderId has been assigned to $driverName.',
    );
  }

  Future<void> triggerPaymentCollectedAlert(String customerName, double amount) async {
    await _notificationService.showNotification(
      id: 103,
      title: '💰 Payment Received',
      body: 'Payment of ₹$amount collected from $customerName.',
    );
  }
}
