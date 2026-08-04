import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class AppsScriptService {
  final DioClient _dioClient;

  AppsScriptService(this._dioClient);

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dioClient.postAction('login', {
        'username': username,
        'password': password,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('AppsScript login error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchDashboardMetrics() async {
    try {
      final response = await _dioClient.getAction('getDashboard');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('AppsScript fetchDashboard error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchCustomers() async {
    try {
      final response = await _dioClient.getAction('getCustomers');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveCustomer(Map<String, dynamic> customerData) async {
    try {
      final response = await _dioClient.postAction('saveCustomer', customerData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _dioClient.postAction('createOrder', orderData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> recordDelivery(Map<String, dynamic> deliveryData) async {
    try {
      final response = await _dioClient.postAction('completeDelivery', deliveryData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addWaterPurchase(Map<String, dynamic> purchaseData) async {
    try {
      final response = await _dioClient.postAction('addWaterPurchase', purchaseData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> expenseData) async {
    try {
      final response = await _dioClient.postAction('addExpense', expenseData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> recordPayment(Map<String, dynamic> paymentData) async {
    try {
      final response = await _dioClient.postAction('recordPayment', paymentData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
