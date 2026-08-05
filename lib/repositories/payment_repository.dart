import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/customer_model.dart';
import '../models/payment_model.dart';
import 'base_repository.dart';

class PaymentRepository extends BaseRepository {
  final Uuid _uuid = const Uuid();

  Future<Result<List<PaymentModel>>> getPayments() async {
    try {
      final items = HiveService.getAll(AppConstants.paymentBoxName);
      final list = items.map((item) {
        return PaymentModel.fromJson(jsonDecode(item as String));
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return Success(list);
    } catch (e, stack) {
      return Failure('Failed to fetch payments: $e', e, stack);
    }
  }

  Future<Result<PaymentModel>> recordPayment(PaymentModel payment) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.paymentBoxName);
      final id = payment.id.isEmpty ? 'PAY-${_uuid.v4().substring(0, 5).toUpperCase()}' : payment.id;
      final item = payment.copyWith(id: id);

      if (box != null) await box.put(id, jsonEncode(item.toJson()));
      await enqueueSync(
        collection: 'payments',
        docId: id,
        action: 'set',
        data: item.toJson(),
      );

      // Deduct pending dues from customer account
      final custBox = HiveService.getBoxSafe(AppConstants.customerBoxName);
      if (custBox != null) {
        final custStr = custBox.get(payment.customerId);
        if (custStr != null) {
          final cust = CustomerModel.fromJson(jsonDecode(custStr));
          final updatedDues = (cust.pendingDues - payment.amount).clamp(0.0, 999999.0);
          final updatedCust = cust.copyWith(pendingDues: updatedDues);
          await custBox.put(cust.id, jsonEncode(updatedCust.toJson()));
          await enqueueSync(
            collection: 'customers',
            docId: cust.id,
            action: 'set',
            data: updatedCust.toJson(),
          );
        }
      }

      return Success(item);
    } catch (e, stack) {
      return Failure('Failed to record payment: $e', e, stack);
    }
  }
}
