import '../../models/customer_model.dart';
import '../../models/delivery_schedule_model.dart';

abstract class ICustomerRepository {
  Future<List<CustomerModel>> getCustomers();
  Future<CustomerModel?> getCustomerById(String id);
  Future<bool> saveCustomer(CustomerModel customer);
  Future<bool> deleteCustomer(String id);
  
  // Delivery Schedule rules
  Future<DeliveryScheduleModel?> getSchedule(String customerId);
  Future<bool> saveSchedule(DeliveryScheduleModel schedule);
}
