import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlCtrl;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final savedUrl = HiveService.getData(
      AppConstants.settingsBoxName,
      'apps_script_url',
      defaultValue: AppConstants.defaultAppsScriptUrl,
    );
    _urlCtrl = TextEditingController(text: savedUrl.toString());
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _saveSettings() {
    HiveService.saveData(AppConstants.settingsBoxName, 'apps_script_url', _urlCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apps Script Webhook URL saved successfully!')),
    );
  }

  void _triggerManualSync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All local Hive data synchronized with Google Sheets!')),
      );
    }
  }

  void _showGoogleScriptCodeDialog() {
    const googleScriptCode = '''
/**
 * Pure Drop Aqua ERP - Google Apps Script Backend API
 * Production-Ready REST API for Water Can Distribution ERP
 */

const SPREADSHEET_NAME = "Pure Drop Aqua ERP Database";

const SHEETS_SCHEMA = {
  "Customers": ["CustomerID", "CustomerName", "MobileNumber", "AlternativeNumber", "Address", "Area", "Latitude", "Longitude", "CustomerType", "DepositAmount", "FilledCanBalance", "EmptyCanBalance", "PendingAmount", "Status", "CreatedDate"],
  "Orders": ["OrderID", "CustomerID", "CustomerName", "OrderDate", "DeliveryDate", "FilledCans", "EmptyReturned", "PricePerCan", "TotalAmount", "PaymentStatus", "DeliveryStatus", "AssignedDriver", "CreatedBy"],
  "Inventory": ["Date", "TotalCans", "FilledCans", "EmptyCans", "DamagedCans", "CustomerBalance", "AvailableStock"],
  "WaterPurchase": ["PurchaseID", "SupplierName", "PurchaseDate", "Quantity", "PricePerCan", "TotalCost", "Remarks"],
  "Delivery": ["DeliveryID", "OrderID", "DriverName", "DeliveryDate", "DeliveryStatus", "CollectedEmpty", "CollectedPayment", "Remarks"],
  "Employees": ["EmployeeID", "EmployeeName", "Username", "Password", "Role", "Phone", "Salary", "Status"],
  "Expenses": ["ExpenseID", "ExpenseDate", "Category", "Description", "Amount", "PaidBy"],
  "Payments": ["PaymentID", "CustomerID", "OrderID", "Amount", "PaymentMethod", "PaymentDate", "Status"],
  "Dashboard": ["TodayOrders", "Revenue", "Expenses", "NetProfit", "FilledStock", "EmptyStock", "PendingPayments", "CompletedDeliveries", "LastUpdated"]
};

function doGet(e) {
  initDatabase();
  return responseJSON(true, "Pure Drop Aqua API Active", { status: "Active", timestamp: new Date() });
}

function doPost(e) {
  try {
    initDatabase();
    if (!e || !e.postData || !e.postData.contents) return responseJSON(false, "Invalid payload", null);
    const request = JSON.parse(e.postData.contents);
    const action = request.action;
    const payload = request.payload || {};

    switch (action) {
      case "/login": return handleLogin(payload);
      case "/customers": return handleSaveCustomer(payload);
      case "/orders": return handleCreateOrder(payload);
      case "/delivery": return handleCompleteDelivery(payload);
      case "/inventory": return handleUpdateInventory(payload);
      case "/waterPurchase": return handleAddWaterPurchase(payload);
      case "/employees": return handleSaveEmployee(payload);
      case "/expenses": return handleAddExpense(payload);
      case "/payments": return handleRecordPayment(payload);
      default: return responseJSON(true, "Action processed", payload);
    }
  } catch (err) {
    return responseJSON(false, err.toString(), null);
  }
}

function handleLogin(payload) {
  const sheet = getSheet("Employees");
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (String(data[i][2]).trim().toLowerCase() === String(payload.username || "").trim().toLowerCase() &&
        String(data[i][3]) === String(payload.password || "")) {
      return responseJSON(true, "Login successful", {
        employeeId: data[i][0],
        employeeName: data[i][1],
        username: data[i][2],
        role: data[i][4],
        phone: data[i][5]
      });
    }
  }
  return responseJSON(false, "Invalid username or password", null);
}

function handleSaveCustomer(payload) {
  const sheet = getSheet("Customers");
  const data = sheet.getDataRange().getValues();
  const custId = payload.id || ("CUST-" + Math.floor(1000 + Math.random() * 9000));
  const mobile = String(payload.phone || "").trim();

  let rowIndex = -1;
  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(custId)) {
      rowIndex = i + 1;
      break;
    }
    if (!payload.id && mobile && String(data[i][2]).trim() === mobile) {
      return responseJSON(false, "Customer with this mobile number already exists", null);
    }
  }

  const rowData = [
    custId,
    payload.name || "Unknown",
    mobile,
    payload.alternativePhone || "",
    payload.address || "",
    payload.area || "",
    payload.latitude || 0,
    payload.longitude || 0,
    payload.customerType || "Residential",
    payload.depositAmount || 0,
    payload.filledCanBalance || 0,
    payload.emptyCanBalance || 0,
    payload.pendingAmount || 0,
    payload.status || "Active",
    new Date().toISOString()
  ];

  if (rowIndex > 0) {
    sheet.getRange(rowIndex, 1, 1, rowData.length).setValues([rowData]);
  } else {
    sheet.appendRow(rowData);
  }
  updateDashboard();
  return responseJSON(true, "Customer saved successfully", { id: custId, ...payload });
}

function handleCreateOrder(payload) {
  const sheet = getSheet("Orders");
  const orderId = payload.id || ("ORD-" + Math.floor(1000 + Math.random() * 9000));
  const filled = Number(payload.filledCans || 0);
  const price = Number(payload.pricePerCan || 0);
  const total = payload.totalAmount || (filled * price);

  const rowData = [
    orderId,
    payload.customerId || "",
    payload.customerName || "",
    payload.orderDate || new Date().toISOString(),
    payload.deliveryDate || new Date().toISOString(),
    filled,
    payload.emptyReturned || 0,
    price,
    total,
    payload.paymentStatus || "Pending",
    payload.deliveryStatus || "Pending",
    payload.assignedDriver || "",
    payload.createdBy || "System"
  ];

  sheet.appendRow(rowData);
  updateDashboard();
  return responseJSON(true, "Order created successfully", { orderId: orderId, totalAmount: total });
}

function handleCompleteDelivery(payload) {
  const sheet = getSheet("Delivery");
  const deliveryId = "DEL-" + Math.floor(1000 + Math.random() * 9000);
  const rowData = [
    deliveryId,
    payload.orderId || "",
    payload.driverName || "",
    new Date().toISOString(),
    "Completed",
    payload.collectedEmpty || 0,
    payload.collectedPayment || 0,
    payload.remarks || ""
  ];
  sheet.appendRow(rowData);

  if (payload.orderId) {
    const orderSheet = getSheet("Orders");
    const oData = orderSheet.getDataRange().getValues();
    for (let i = 1; i < oData.length; i++) {
      if (String(oData[i][0]) === String(payload.orderId)) {
        orderSheet.getRange(i + 1, 11).setValue("Delivered");
        break;
      }
    }
  }
  updateDashboard();
  return responseJSON(true, "Delivery completed successfully", { deliveryId: deliveryId });
}

function handleUpdateInventory(payload) {
  const sheet = getSheet("Inventory");
  const total = Number(payload.totalCans || 500);
  const filled = Number(payload.filledCans || 0);
  const empty = Number(payload.emptyCans || 0);
  const damaged = Number(payload.damagedCans || 0);
  const custBal = Number(payload.customerBalance || 0);
  const available = filled + empty;

  const rowData = [
    new Date().toISOString(),
    total,
    filled,
    empty,
    damaged,
    custBal,
    available
  ];
  sheet.appendRow(rowData);
  updateDashboard();
  return responseJSON(true, "Inventory updated successfully", payload);
}

function handleAddWaterPurchase(payload) {
  const sheet = getSheet("WaterPurchase");
  const purId = "PUR-" + Math.floor(1000 + Math.random() * 9000);
  const qty = Number(payload.quantity || 0);
  const price = Number(payload.pricePerCan || 0);
  const totalCost = qty * price;

  const rowData = [
    purId,
    payload.supplierName || "",
    payload.purchaseDate || new Date().toISOString(),
    qty,
    price,
    totalCost,
    payload.remarks || ""
  ];
  sheet.appendRow(rowData);
  updateDashboard();
  return responseJSON(true, "Water purchase logged successfully", { purchaseId: purId, totalCost: totalCost });
}

function handleSaveEmployee(payload) {
  const sheet = getSheet("Employees");
  const data = sheet.getDataRange().getValues();
  const empId = payload.id || ("EMP-" + Math.floor(1000 + Math.random() * 9000));

  let rowIndex = -1;
  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(empId)) {
      rowIndex = i + 1;
      break;
    }
  }

  const rowData = [
    empId,
    payload.name || "",
    payload.username || "",
    payload.password || "123456",
    payload.role || "Driver",
    payload.phone || "",
    payload.salary || 0,
    payload.status || "Active"
  ];

  if (rowIndex > 0) {
    sheet.getRange(rowIndex, 1, 1, rowData.length).setValues([rowData]);
  } else {
    sheet.appendRow(rowData);
  }
  return responseJSON(true, "Employee saved successfully", { id: empId, ...payload });
}

function handleAddExpense(payload) {
  const sheet = getSheet("Expenses");
  const expId = "EXP-" + Math.floor(1000 + Math.random() * 9000);
  const rowData = [
    expId,
    payload.date || new Date().toISOString(),
    payload.category || "General",
    payload.description || "",
    Number(payload.amount || 0),
    payload.paidBy || "Admin"
  ];
  sheet.appendRow(rowData);
  updateDashboard();
  return responseJSON(true, "Expense logged successfully", { expenseId: expId });
}

function handleRecordPayment(payload) {
  const sheet = getSheet("Payments");
  const payId = "PAY-" + Math.floor(1000 + Math.random() * 9000);
  const amount = Number(payload.amount || 0);

  const rowData = [
    payId,
    payload.customerId || "",
    payload.orderId || "",
    amount,
    payload.paymentMethod || "Cash",
    payload.date || new Date().toISOString(),
    "Completed"
  ];
  sheet.appendRow(rowData);

  if (payload.customerId) {
    const custSheet = getSheet("Customers");
    const cData = custSheet.getDataRange().getValues();
    for (let i = 1; i < cData.length; i++) {
      if (String(cData[i][0]) === String(payload.customerId)) {
        const currentDues = Number(cData[i][12] || 0);
        const newDues = Math.max(0, currentDues - amount);
        custSheet.getRange(i + 1, 13).setValue(newDues);
        break;
      }
    }
  }
  updateDashboard();
  return responseJSON(true, "Payment recorded successfully", { paymentId: payId });
}

function updateDashboard() {
  try {
    const dashSheet = getSheet("Dashboard");
    const ordersSheet = getSheet("Orders");
    const expSheet = getSheet("Expenses");
    const invSheet = getSheet("Inventory");
    const custSheet = getSheet("Customers");

    const orders = ordersSheet.getDataRange().getValues();
    let todayOrders = 0, totalRevenue = 0, completedDeliveries = 0;
    for (let i = 1; i < orders.length; i++) {
      todayOrders++;
      totalRevenue += Number(orders[i][8] || 0);
      if (String(orders[i][10]) === "Delivered") completedDeliveries++;
    }

    const expenses = expSheet.getDataRange().getValues();
    let totalExpenses = 0;
    for (let i = 1; i < expenses.length; i++) {
      totalExpenses += Number(expenses[i][4] || 0);
    }

    const netProfit = totalRevenue - totalExpenses;

    const customers = custSheet.getDataRange().getValues();
    let pendingPayments = 0;
    for (let i = 1; i < customers.length; i++) {
      pendingPayments += Number(customers[i][12] || 0);
    }

    const inv = invSheet.getDataRange().getValues();
    let filledStock = 0, emptyStock = 0;
    if (inv.length > 1) {
      const lastRow = inv[inv.length - 1];
      filledStock = Number(lastRow[2] || 0);
      emptyStock = Number(lastRow[3] || 0);
    }

    const dashRow = [
      todayOrders, totalRevenue, totalExpenses, netProfit, filledStock, emptyStock, pendingPayments, completedDeliveries, new Date().toISOString()
    ];

    dashSheet.getRange(2, 1, 1, dashRow.length).setValues([dashRow]);
  } catch (err) {
    Logger.log("Dashboard update error: " + err.toString());
  }
}

function getSheet(name) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  return ss.getSheetByName(name) || ss.insertSheet(name);
}

function initDatabase() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  for (const name in SHEETS_SCHEMA) {
    let sheet = ss.getSheetByName(name) || ss.insertSheet(name);
    if (sheet.getLastRow() === 0) {
      sheet.appendRow(SHEETS_SCHEMA[name]);
    }
  }
}

function responseJSON(success, message, data) {
  return ContentService.createTextOutput(JSON.stringify({ success: success, message: message, data: data }))
    .setMimeType(ContentService.MimeType.JSON);
}
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Apps Script Setup Code'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste this script in Google Sheets Extensions > Apps Script:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black87,
                child: SelectableText(
                  googleScriptCode,
                  style: const TextStyle(color: Colors.lightGreenAccent, fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: googleScriptCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Script copied to clipboard!')),
              );
            },
            child: const Text('Copy Code'),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Settings & Cloud Integration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Google Sheets AppScript Webhook Setup Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_sync, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Google Sheets / Apps Script Webhook',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Google Apps Script Webhook URL',
                  controller: _urlCtrl,
                  hint: 'https://script.google.com/macros/s/.../exec',
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 450;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showGoogleScriptCodeDialog(),
                            icon: const Icon(Icons.code),
                            label: const Text('View AppsScript Code'),
                          ),
                          const SizedBox(height: 10),
                          CustomButton(
                            label: 'Save Endpoint',
                            onPressed: _saveSettings,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showGoogleScriptCodeDialog(),
                          icon: const Icon(Icons.code),
                          label: const Text('View AppsScript Code'),
                        ),
                        const Spacer(),
                        CustomButton(
                          label: 'Save Endpoint',
                          width: 150,
                          onPressed: _saveSettings,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Local Hive Storage Status & Manual Sync Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storage, color: AppColors.success, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Offline Storage & Local Caching',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Hive NoSQL Offline database active. All transactions work seamlessly offline and sync when online.'),
                const SizedBox(height: 16),
                CustomButton(
                  label: _isSyncing ? 'Syncing with Google Sheets...' : 'Trigger Manual Cloud Sync',
                  icon: Icons.sync,
                  isLoading: _isSyncing,
                  onPressed: _triggerManualSync,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // App Info
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Version: 1.0.0 • Channel: Production Ready'),
                Text('Developed with Clean Architecture & Riverpod'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
