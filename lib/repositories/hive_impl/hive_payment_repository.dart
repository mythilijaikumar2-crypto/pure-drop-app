import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/hive_service.dart';
import '../../models/payment_model.dart';
import '../interfaces/i_payment_repository.dart';

class HivePaymentRepository implements IPaymentRepository {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<PaymentModel>> getPayments() async {
    try {
      final items = HiveService.getAll(AppConstants.paymentBoxName);
      final list = items.map((item) {
        final Map<String, dynamic> json = jsonDecode(item as String);
        return PaymentModel.fromJson(json);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByCustomer(String customerId) async {
    final all = await getPayments();
    return all.where((p) => p.customerId == customerId).toList();
  }

  @override
  Future<bool> recordPayment(PaymentModel payment) async {
    final box = HiveService.getBox(AppConstants.paymentBoxName);
    final id = payment.id.isEmpty
        ? 'PAY-${_uuid.v4().substring(0, 5).toUpperCase()}'
        : payment.id;
    final updated = payment.copyWith(id: id);

    try {
      await box.put(id, jsonEncode(updated.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
