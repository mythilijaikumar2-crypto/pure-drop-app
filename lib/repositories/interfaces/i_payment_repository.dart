import '../../models/payment_model.dart';

abstract class IPaymentRepository {
  Future<List<PaymentModel>> getPayments();
  Future<List<PaymentModel>> getPaymentsByCustomer(String customerId);
  Future<bool> recordPayment(PaymentModel payment);
}
