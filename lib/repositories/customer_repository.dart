import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/customer_model.dart';
import 'base_repository.dart';

class CustomerRepository extends BaseRepository {
  final Uuid _uuid = const Uuid();

  Future<Result<List<CustomerModel>>> getCustomers() async {
    try {
      final items = HiveService.getAll(AppConstants.customerBoxName);
      final customers = items.map((item) {
        final Map<String, dynamic> json = jsonDecode(item as String);
        return CustomerModel.fromJson(json);
      }).toList();
      return Success(customers);
    } catch (e, stack) {
      return Failure('Failed to load customer list: $e', e, stack);
    }
  }

  Future<Result<CustomerModel>> saveCustomer(CustomerModel customer, {UserRole? role}) async {
    try {
      if (role != null && role != UserRole.admin) {
        return const Failure('Unauthorized: Customer modification requires Admin privilege.');
      }
      final box = HiveService.getBox(AppConstants.customerBoxName);
      final id = customer.id.isEmpty ? 'CUST-${_uuid.v4().substring(0, 5).toUpperCase()}' : customer.id;
      final updatedCustomer = customer.copyWith(id: id);

      await box.put(id, jsonEncode(updatedCustomer.toJson()));
      await enqueueSync(
        collection: 'customers',
        docId: id,
        action: 'set',
        data: updatedCustomer.toJson(),
      );

      return Success(updatedCustomer);
    } catch (e, stack) {
      return Failure('Failed to save customer: $e', e, stack);
    }
  }

  Future<Result<bool>> deleteCustomer(String id, {UserRole? role}) async {
    try {
      if (role != null && role != UserRole.admin) {
        return const Failure('Unauthorized: Customer deletion requires Admin privilege.');
      }
      final box = HiveService.getBox(AppConstants.customerBoxName);
      await box.delete(id);
      await enqueueSync(
        collection: 'customers',
        docId: id,
        action: 'delete',
        data: {},
      );
      return const Success(true);
    } catch (e, stack) {
      return Failure('Failed to delete customer: $e', e, stack);
    }
  }
}
