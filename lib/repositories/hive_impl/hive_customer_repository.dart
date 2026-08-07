import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/hive_service.dart';
import '../../models/customer_model.dart';
import '../../models/delivery_schedule_model.dart';
import '../interfaces/i_customer_repository.dart';

class HiveCustomerRepository implements ICustomerRepository {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final items = HiveService.getAll(AppConstants.customerBoxName);
      return items.map((item) {
        final Map<String, dynamic> json = jsonDecode(item as String);
        return CustomerModel.fromJson(json);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      final box = HiveService.getBox(AppConstants.customerBoxName);
      final raw = box.get(id);
      if (raw == null) return null;
      return CustomerModel.fromJson(jsonDecode(raw as String));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> saveCustomer(CustomerModel customer) async {
    final box = HiveService.getBox(AppConstants.customerBoxName);
    final id = customer.id.isEmpty
        ? 'CUST-${_uuid.v4().substring(0, 5).toUpperCase()}'
        : customer.id;
    final updatedCustomer = customer.copyWith(id: id);

    try {
      await box.put(id, jsonEncode(updatedCustomer.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> deleteCustomer(String id) async {
    final box = HiveService.getBox(AppConstants.customerBoxName);
    try {
      await box.delete(id);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<DeliveryScheduleModel?> getSchedule(String customerId) async {
    try {
      final box = HiveService.getBox(AppConstants.settingsBoxName);
      final raw = box.get('schedule_$customerId');
      if (raw == null) return null;
      return DeliveryScheduleModel.fromJson(jsonDecode(raw as String));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> saveSchedule(DeliveryScheduleModel schedule) async {
    try {
      final box = HiveService.getBox(AppConstants.settingsBoxName);
      await box.put('schedule_${schedule.customerId}', jsonEncode(schedule.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }
}
