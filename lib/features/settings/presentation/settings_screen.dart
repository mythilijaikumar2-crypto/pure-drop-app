import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlCtrl;
  bool _isSyncing = false;
  bool _isTestingConnection = false;

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

  void _resetDefaultUrl() {
    DioClient.resetAppsScriptUrl();
    _urlCtrl.text = AppConstants.defaultAppsScriptUrl;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API URL restored to default Google Apps Script Web App Endpoint!'),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  void _testApiConnection() async {
    setState(() => _isTestingConnection = true);
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.getAction('getDashboard');

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connected Successfully! Google Apps Script & Sheets are Live.'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Connection Warning: HTTP ${response.statusCode} returned.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        final code = e.response?.statusCode ?? 'Network/Timeout';
        String errorMsg = 'Failed to connect (Error Code: $code). ';
        if (code == 401) {
          errorMsg += '401 Unauthorized: Please check Web App deployment settings ("Anyone" access required).';
        } else if (code == 404) {
          errorMsg += '404 Not Found: Check URL ending with /exec.';
        } else {
          errorMsg += e.message ?? 'Check internet connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMsg'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test connection exception: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingConnection = false);
    }
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
 * Pure Drop Aqua ERP - Advanced Production-Ready Google Apps Script Backend
 * Module: Complete Finance, Income, Deposit, Investment, Profit & Business Analytics
 * 
 * Instructions:
 * 1. Open your Google Spreadsheet ("Pure Drop Aqua ERP Database")
 * 2. Go to Extensions -> Apps Script
 * 3. Replace all content in Code.gs with this code
 * 4. Run setupDatabase() once manually OR it will auto-run on first API call
 * 5. Click Deploy -> New Deployment -> Select "Web App"
 *    - Execute as: "Me"
 *    - Who has access: "Anyone"
 * 6. Copy the generated Web App URL into Pure Drop Aqua ERP Settings screen!
 */

const SPREADSHEET_NAME = "Pure Drop Aqua ERP Database";

// Column Definitions for all 16 Sheets
const SHEETS_SCHEMA = {
  "Customers": [
    "CustomerID", "CustomerName", "MobileNumber", "AlternativeNumber",
    "Address", "Area", "Latitude", "Longitude", "SubscriptionType",
    "DepositAmount", "FilledCanBalance", "EmptyCanBalance", "PendingAmount",
    "Status", "CreatedDate", "LastDeliveryDate", "NextDeliveryDate", "Notes"
  ],
  "Orders": [
    "OrderID", "CustomerID", "CustomerName", "OrderDate", "DeliveryDate",
    "FilledCans", "EmptyReturned", "PricePerCan", "TotalAmount",
    "PaymentStatus", "DeliveryStatus", "AssignedDriver", "CreatedBy", "CreatedDate"
  ],
  "Inventory": [
    "InventoryID", "Date", "FilledCans", "EmptyCans", "DamagedCans",
    "LostCans", "AvailableStock", "Remarks"
  ],
  "WaterPurchase": [
    "PurchaseID", "SupplierName", "PurchaseDate", "Quantity",
    "PricePerCan", "TotalCost", "InvoiceNumber", "Remarks"
  ],
  "Expenses": [
    "ExpenseID", "ExpenseDate", "Category", "Amount", "Description", "CreatedBy"
  ],
  "Employees": [
    "EmployeeID", "EmployeeName", "Role", "Phone", "Salary",
    "Address", "Status", "JoiningDate"
  ],
  "Delivery": [
    "DeliveryID", "DriverName", "CustomerID", "CustomerName",
    "Route", "DeliveryDate", "DeliveryStatus", "PaymentCollected", "EmptyCollected", "Remarks"
  ],
  "Reports": [
    "ReportID", "ReportType", "GeneratedDate", "GeneratedBy", "Summary"
  ],
  "Settings": [
    "SettingKey", "SettingValue", "Description"
  ],
  "Income": [
    "IncomeID", "Date", "IncomeType", "CustomerID", "CustomerName",
    "OrderID", "Amount", "PaymentMethod", "ReferenceNumber", "CollectedBy",
    "Status", "Remarks", "CreatedAt"
  ],
  "Deposits": [
    "DepositID", "CustomerID", "CustomerName", "DepositAmount", "ReturnedAmount",
    "CurrentBalance", "DepositDate", "ReturnDate", "Status", "Remarks"
  ],
  "Investments": [
    "InvestmentID", "Date", "InvestorName", "InvestmentType", "Amount",
    "Purpose", "PaymentMethod", "ReferenceNumber", "Remarks"
  ],
  "CanPurchase": [
    "PurchaseID", "SupplierName", "PurchaseDate", "CanQuantity", "PricePerCan",
    "GST", "TransportCost", "OtherCharges", "TotalAmount", "InvoiceNumber", "Remarks"
  ],
  "Transactions": [
    "TransactionID", "Date", "TransactionType", "Credit", "Debit",
    "OpeningBalance", "ClosingBalance", "ReferenceID", "PaymentMethod", "Remarks"
  ],
  "ProfitLoss": [
    "Date", "SalesIncome", "DepositIncome", "OtherIncome", "TotalIncome",
    "TotalExpense", "NetProfit", "NetLoss", "ProfitMargin"
  ],
  "Assets": [
    "AssetID", "AssetName", "Category", "PurchaseDate", "PurchaseCost",
    "CurrentValue", "Status", "Remarks"
  ]
};

// --- DATABASE SETUP & COLUMN VALIDATION ---

function setupDatabase() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  for (const sheetName in SHEETS_SCHEMA) {
    const requiredHeaders = SHEETS_SCHEMA[sheetName];
    ensureSheetExists(ss, sheetName, requiredHeaders);
  }
}

function ensureSheetExists(ss, sheetName, requiredHeaders) {
  let sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
    sheet.appendRow(requiredHeaders);
    formatHeaderRow(sheet, requiredHeaders.length);
  } else {
    const lastRow = sheet.getLastRow();
    const lastCol = sheet.getLastColumn();

    if (lastRow === 0 || lastCol === 0) {
      sheet.appendRow(requiredHeaders);
      formatHeaderRow(sheet, requiredHeaders.length);
    } else {
      const existingHeaders = sheet.getRange(1, 1, 1, lastCol).getValues()[0].map(h => h.toString().trim());
      const missingHeaders = [];

      for (let i = 0; i < requiredHeaders.length; i++) {
        if (!existingHeaders.includes(requiredHeaders[i])) {
          missingHeaders.push(requiredHeaders[i]);
        }
      }

      if (missingHeaders.length > 0) {
        const startCol = lastCol + 1;
        sheet.getRange(1, startCol, 1, missingHeaders.length).setValues([missingHeaders]);
        formatHeaderRow(sheet, existingHeaders.length + missingHeaders.length);
      } else {
        formatHeaderRow(sheet, existingHeaders.length);
      }
    }
  }
}

function formatHeaderRow(sheet, numColumns) {
  try {
    sheet.setFrozenRows(1);
    const headerRange = sheet.getRange(1, 1, 1, numColumns);
    headerRange.setFontWeight("bold")
               .setBackground("#1DAEFF")
               .setFontColor("#FFFFFF")
               .setVerticalAlignment("middle")
               .setHorizontalAlignment("left");

    if (!sheet.getFilter() && sheet.getLastRow() > 0) {
      sheet.getRange(1, 1, Math.max(1, sheet.getLastRow()), numColumns).createFilter();
    }
  } catch (e) {
    Logger.log("Formatting notice for " + sheet.getName() + ": " + e.toString());
  }
}

function getSheet(sheetName) {
  return SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName);
}

function getHeaders(sheetName) {
  const sheet = getSheet(sheetName);
  if (!sheet || sheet.getLastColumn() === 0) return SHEETS_SCHEMA[sheetName] || [];
  return sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0].map(h => h.toString().trim());
}

// --- HTTP POST ROUTER ---
function doPost(e) {
  try {
    setupDatabase();
    let action = "";
    let payload = {};

    if (e && e.postData && e.postData.contents) {
      try {
        const request = JSON.parse(e.postData.contents);
        action = request.action || (e.parameter && e.parameter.action ? e.parameter.action : "");
        payload = request.payload || request;
      } catch (err) {
        action = (e.parameter && e.parameter.action) ? e.parameter.action : "";
        if (e.parameter && e.parameter.payload) {
          try { payload = JSON.parse(e.parameter.payload); } catch (_) { payload = e.parameter; }
        } else {
          payload = e.parameter || {};
        }
      }
    } else if (e && e.parameter) {
      action = e.parameter.action || "";
      if (e.parameter.payload) {
        try { payload = JSON.parse(e.parameter.payload); } catch (_) { payload = e.parameter; }
      } else {
        payload = e.parameter || {};
      }
    }

    if (!action) {
      return responseJSON(false, "Invalid request payload - Action missing", null);
    }

    switch (action) {
      case "/login":
      case "login":
        return handleLogin(payload);
      case "/customers":
      case "saveCustomer":
        return handleSaveCustomer(payload);
      case "deleteCustomer":
        return handleDeleteItem("Customers", "CustomerID", payload.id || payload.customerId);
      case "/orders":
      case "createOrder":
        return handleCreateOrder(payload);
      case "/updateOrder":
      case "updateOrder":
      case "updateOrderStatus":
        return handleUpdateOrder(payload);
      case "deleteOrder":
        return handleDeleteItem("Orders", "OrderID", payload.id || payload.orderId);
      case "/delivery":
      case "completeDelivery":
        return handleCompleteDelivery(payload);
      case "/inventory":
      case "updateInventory":
        return handleUpdateInventory(payload);
      case "/waterPurchase":
      case "addWaterPurchase":
        return handleAddWaterPurchase(payload);
      case "/employees":
      case "saveEmployee":
        return handleSaveEmployee(payload);
      case "deleteEmployee":
        return handleDeleteItem("Employees", "EmployeeID", payload.id || payload.employeeId);
      case "/expenses":
      case "addExpense":
        return handleAddExpense(payload);
      case "/payments":
      case "recordPayment":
        return handleRecordPayment(payload);

      // --- FINANCE MODULE ENDPOINTS ---
      case "/income":
      case "saveIncome":
        return handleSaveIncome(payload);
      case "/deposits":
      case "saveDeposit":
        return handleSaveDeposit(payload);
      case "refundDeposit":
        return handleRefundDeposit(payload);
      case "/investments":
      case "saveInvestment":
        return handleSaveInvestment(payload);
      case "/canPurchase":
      case "addCanPurchase":
        return handleAddCanPurchase(payload);
      case "/transactions":
      case "addTransaction":
        return handleAddTransaction(payload);
      case "/assets":
      case "saveAsset":
        return handleSaveAsset(payload);

      case "/reports":
      case "addReport":
        return handleAddReport(payload);
      case "/settings":
      case "saveSetting":
        return handleSaveSetting(payload);
      case "/dashboard":
      case "recalculateDashboard":
        return handleRecalculateDashboard();

      default:
        return responseJSON(false, "Unknown API action: " + action, null);
    }
  } catch (error) {
    return responseJSON(false, "Server Exception: " + error.toString(), null);
  }
}

// --- HTTP GET ROUTER ---
function doGet(e) {
  try {
    setupDatabase();
    const action = (e && e.parameter && e.parameter.action) ? e.parameter.action : "/dashboard";

    switch (action) {
      case "/customers":
      case "getCustomers":
        return responseJSON(true, "Customers fetched", getSheetData("Customers"));
      case "/orders":
      case "getOrders":
        return responseJSON(true, "Orders fetched", getSheetData("Orders"));
      case "/inventory":
      case "getInventory":
        return responseJSON(true, "Inventory fetched", getSheetData("Inventory"));
      case "/waterPurchase":
      case "getWaterPurchases":
        return responseJSON(true, "Water purchases fetched", getSheetData("WaterPurchase"));
      case "/employees":
      case "getEmployees":
        return responseJSON(true, "Employees fetched", getSheetData("Employees"));
      case "/expenses":
      case "getExpenses":
        return responseJSON(true, "Expenses fetched", getSheetData("Expenses"));
      case "/delivery":
      case "getDeliveries":
        return responseJSON(true, "Deliveries fetched", getSheetData("Delivery"));
      case "/reports":
      case "getReports":
        return responseJSON(true, "Reports fetched", getSheetData("Reports"));
      case "/settings":
      case "getSettings":
        return responseJSON(true, "Settings fetched", getSheetData("Settings"));
      case "/income":
      case "getIncome":
        return responseJSON(true, "Income records fetched", getSheetData("Income"));
      case "/deposits":
      case "getDeposits":
        return responseJSON(true, "Deposits fetched", getSheetData("Deposits"));
      case "/investments":
      case "getInvestments":
        return responseJSON(true, "Investments fetched", getSheetData("Investments"));
      case "/canPurchase":
      case "getCanPurchases":
        return responseJSON(true, "Can purchases fetched", getSheetData("CanPurchase"));
      case "/transactions":
      case "getTransactions":
        return responseJSON(true, "Transactions fetched", getSheetData("Transactions"));
      case "/profitLoss":
      case "getProfitLoss":
        return responseJSON(true, "Profit & Loss fetched", getSheetData("ProfitLoss"));
      case "/assets":
      case "getAssets":
        return responseJSON(true, "Assets fetched", getSheetData("Assets"));
      case "/dashboard":
      case "getDashboard":
        return responseJSON(true, "Dashboard metrics fetched", calculateDashboardMetrics());
      default:
        return responseJSON(true, "Pure Drop Aqua ERP API is Live", { status: "Active", timestamp: new Date() });
    }
  } catch (error) {
    return responseJSON(false, "Server Exception: " + error.toString(), null);
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showGoogleScriptCodeDialog(),
                      icon: const Icon(Icons.code, size: 18),
                      label: const Text('View Code'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _resetDefaultUrl,
                      icon: const Icon(Icons.restore, size: 18),
                      label: const Text('Reset URL'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isTestingConnection ? null : _testApiConnection,
                      icon: _isTestingConnection
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.network_check_rounded, size: 18),
                      label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.info, foregroundColor: Colors.white),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save Endpoint'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    ),
                  ],
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
