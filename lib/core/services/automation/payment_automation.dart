import '../../../models/customer_model.dart';
import '../../../models/payment_model.dart';
import '../../../repositories/interfaces/i_customer_repository.dart';
import '../../../repositories/interfaces/i_payment_repository.dart';
import '../../../core/constants/app_enums.dart';
import 'timeline_automation.dart';

class PaymentAutomation {
  final IPaymentRepository _paymentRepo;
  final ICustomerRepository _customerRepo;
  final TimelineAutomation _timelineAutomation;

  PaymentAutomation(
    this._paymentRepo,
    this._customerRepo,
    this._timelineAutomation,
  );

  Future<bool> collectPayment({
    required String customerId,
    required String customerName,
    required double amount,
    required PaymentMode paymentMode,
    String referenceNumber = '',
    String collectedBy = 'Admin',
    String notes = '',
  }) async {
    if (amount <= 0) return false;

    final customer = await _customerRepo.getCustomerById(customerId);
    if (customer == null) return false;

    final payment = PaymentModel(
      id: '',
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      paymentMode: paymentMode,
      referenceNo: referenceNumber,
      notes: notes,
      date: DateTime.now(),
    );

    final recorded = await _paymentRepo.recordPayment(payment);
    if (!recorded) return false;

    // Reduce customer pending dues
    final updatedDues = (customer.pendingDues - amount).clamp(0.0, 999999.0);
    final updatedCustomer = customer.copyWith(pendingDues: updatedDues);
    await _customerRepo.saveCustomer(updatedCustomer);

    await _timelineAutomation.logEvent(
      title: 'Payment Collected',
      description: 'Collected ₹$amount from ${customer.name} via ${paymentMode.displayName}. Dues left: ₹$updatedDues',
      category: 'Payment',
      recordId: customerId,
      performedBy: collectedBy,
      metadata: {'amount': amount, 'mode': paymentMode.name},
    );

    return true;
  }
}
