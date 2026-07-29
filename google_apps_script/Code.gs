/**
 * Pure Drop Aqua ERP - Google Apps Script Backend API
 * Production-Ready Apps Script for Water Can Distribution ERP
 * 
 * Instructions:
 * 1. Open Google Sheets -> Extensions -> Apps Script
 * 2. Paste this complete Code.gs script
 * 3. Click Deploy -> New Deployment -> Select "Web App"
 * 4. Execute as: "Me"
 * 5. Who has access: "Anyone"
 * 6. Copy the Web App URL into Pure Drop Aqua ERP Settings!
 */

const SPREADSHEET_NAME = "Pure Drop Aqua ERP Database";

// Column Definitions for all 9 Sheets
const SHEETS_SCHEMA = {
  "Customers": [
    "CustomerID", "CustomerName", "MobileNumber", "AlternativeNumber",
    "Address", "Area", "Latitude", "Longitude", "CustomerType",
    "DepositAmount", "FilledCanBalance", "EmptyCanBalance", "PendingAmount",
    "Status", "CreatedDate"
  ],
  "Orders": [
    "OrderID", "CustomerID", "CustomerName", "OrderDate", "DeliveryDate",
    "FilledCans", "EmptyReturned", "PricePerCan", "TotalAmount",
    "PaymentStatus", "DeliveryStatus", "AssignedDriver", "CreatedBy"
  ],
  "Inventory": [
    "Date", "TotalCans", "FilledCans", "EmptyCans", "DamagedCans",
    "CustomerBalance", "AvailableStock"
  ],
  "WaterPurchase": [
    "PurchaseID", "SupplierName", "PurchaseDate", "Quantity",
    "PricePerCan", "TotalCost", "Remarks"
  ],
  "Delivery": [
    "DeliveryID", "OrderID", "DriverName", "DeliveryDate",
    "DeliveryStatus", "CollectedEmpty", "CollectedPayment", "Remarks"
  ],
  "Employees": [
    "EmployeeID", "EmployeeName", "Username", "Password", "Role",
    "Phone", "Salary", "Status"
  ],
  "Expenses": [
    "ExpenseID", "ExpenseDate", "Category", "Description", "Amount", "PaidBy"
  ],
  "Payments": [
    "PaymentID", "CustomerID", "OrderID", "Amount", "PaymentMethod",
    "PaymentDate", "Status"
  ],
  "Dashboard": [
    "TodayOrders", "Revenue", "Expenses", "NetProfit",
    "FilledStock", "EmptyStock", "PendingPayments", "CompletedDeliveries", "LastUpdated"
  ]
};

// --- HTTP POST ROUTER ---
function doPost(e) {
  try {
    initDatabase();
    if (!e || !e.postData || !e.postData.contents) {
      return responseJSON(false, "Invalid request payload", null);
    }

    const request = JSON.parse(e.postData.contents);
    const action = request.action;
    const payload = request.payload || {};

    switch (action) {
      case "/login":
      case "login":
        return handleLogin(payload);
      case "/customers":
      case "saveCustomer":
        return handleSaveCustomer(payload);
      case "/orders":
      case "createOrder":
        return handleCreateOrder(payload);
      case "/updateOrder":
        return handleUpdateOrder(payload);
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
      case "/expenses":
      case "addExpense":
        return handleAddExpense(payload);
      case "/payments":
      case "recordPayment":
        return handleRecordPayment(payload);
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
    initDatabase();
    const action = e.parameter.action || "/dashboard";

    switch (action) {
      case "/customers":
        return responseJSON(true, "Customers fetched", getSheetData("Customers"));
      case "/orders":
        return responseJSON(true, "Orders fetched", getSheetData("Orders"));
      case "/inventory":
        return responseJSON(true, "Inventory fetched", getSheetData("Inventory"));
      case "/waterPurchase":
        return responseJSON(true, "Water purchases fetched", getSheetData("WaterPurchase"));
      case "/employees":
        return responseJSON(true, "Employees fetched", getSheetData("Employees"));
      case "/expenses":
        return responseJSON(true, "Expenses fetched", getSheetData("Expenses"));
      case "/payments":
        return responseJSON(true, "Payments fetched", getSheetData("Payments"));
      case "/dashboard":
        return responseJSON(true, "Dashboard metrics fetched", calculateDashboardMetrics());
      default:
        return responseJSON(true, "Pure Drop Aqua API is Live", { status: "Active", timestamp: new Date() });
    }
  } catch (error) {
    return responseJSON(false, "Server Exception: " + error.toString(), null);
  }
}

// --- DATABASE INITIALIZATION & SCHEMA FORMATTER ---
function initDatabase() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  for (const sheetName in SHEETS_SCHEMA) {
    let sheet = ss.getSheetByName(sheetName);
    if (!sheet) {
      sheet = ss.insertSheet(sheetName);
    }
    if (sheet.getLastRow() === 0) {
      const headers = SHEETS_SCHEMA[sheetName];
      sheet.appendRow(headers);
      sheet.getRange(1, 1, 1, headers.length).setFontWeight("bold").setBackground("#1DAEFF").setFontColor("#FFFFFF");
    }
  }
}

// --- HANDLER IMPLEMENTATIONS ---

function handleLogin(payload) {
  const username = (payload.username || "").toString().trim().toLowerCase();
  const password = (payload.password || "").toString().trim();

  if (!username || !password) {
    return responseJSON(false, "Username and password are required", null);
  }

  // Pre-configured Admin credentials
  if ((username === "admin" || username === "puredrop") && password === "admin123") {
    return responseJSON(true, "Login successful", {
      employeeId: "ADM-001",
      name: "Pure Drop Admin",
      username: "admin",
      role: "Admin",
      status: "Active"
    });
  }

  // Pre-configured Driver credentials
  if ((username === "driver" || username === "ramesh") && password === "driver123") {
    return responseJSON(true, "Login successful", {
      employeeId: "DRV-101",
      name: "Ramesh Kumar",
      username: "driver",
      role: "Delivery Boy",
      status: "Active"
    });
  }

  // Search Employees sheet
  const employees = getSheetData("Employees");
  const found = employees.find(emp => 
    (emp.Username || "").toString().trim().toLowerCase() === username &&
    (emp.Password || "").toString().trim() === password
  );

  if (found) {
    return responseJSON(true, "Login successful", found);
  }

  return responseJSON(false, "Invalid username or password", null);
}

function handleSaveCustomer(payload) {
  if (!payload.name || !payload.phone) {
    return responseJSON(false, "Customer Name and Mobile Number are required", null);
  }

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Customers");
  const data = sheet.getDataRange().getValues();

  let customerId = payload.id || "";
  let rowIndex = -1;

  if (customerId) {
    for (let i = 1; i < data.length; i++) {
      if (data[i][0] === customerId) {
        rowIndex = i + 1;
        break;
      }
    }
  }

  if (!customerId) {
    customerId = "CUST-" + (1000 + data.length);
  }

  const row = [
    customerId,
    payload.name,
    payload.phone,
    payload.alternativePhone || "",
    payload.address || "",
    payload.area || "",
    payload.latitude || 0.0,
    payload.longitude || 0.0,
    payload.customerType || "Commercial",
    payload.depositAmount || 0,
    payload.canBalance || 0,
    payload.emptyCanBalance || 0,
    payload.pendingDues || 0.0,
    payload.status || "Active",
    new Date()
  ];

  if (rowIndex > 1) {
    sheet.getRange(rowIndex, 1, 1, row.length).setValues([row]);
  } else {
    sheet.appendRow(row);
  }

  return responseJSON(true, "Customer saved successfully", { customerId: customerId });
}

function handleCreateOrder(payload) {
  if (!payload.customerId || !payload.quantity) {
    return responseJSON(false, "Customer ID and Quantity are required", null);
  }

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Orders");
  const lastRow = sheet.getLastRow();

  const orderId = payload.id || ("ORD-" + (1000 + lastRow));
  const row = [
    orderId,
    payload.customerId,
    payload.customerName || "",
    new Date(),
    payload.deliveryDate || new Date(),
    payload.quantity || 1,
    0,
    payload.unitPrice || 35.0,
    payload.totalAmount || (payload.quantity * 35.0),
    payload.paymentStatus || "pending",
    payload.status || "pending",
    payload.assignedDriverName || "",
    payload.createdBy || "Admin"
  ];

  sheet.appendRow(row);
  return responseJSON(true, "Order created successfully", { orderId: orderId });
}

function handleUpdateOrder(payload) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Orders");
  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === payload.id) {
      sheet.getRange(i + 1, 10).setValue(payload.paymentStatus || data[i][9]);
      sheet.getRange(i + 1, 11).setValue(payload.status || data[i][10]);
      sheet.getRange(i + 1, 12).setValue(payload.assignedDriverName || data[i][11]);
      return responseJSON(true, "Order updated successfully", payload);
    }
  }
  return responseJSON(false, "Order ID not found", null);
}

function handleCompleteDelivery(payload) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const deliverySheet = ss.getSheetByName("Delivery");

  const deliveryId = "DEL-" + (1000 + deliverySheet.getLastRow());
  const row = [
    deliveryId,
    payload.orderId,
    payload.driverName || "Driver",
    new Date(),
    "Delivered",
    payload.collectedEmpty || 0,
    payload.collectedPayment || 0.0,
    payload.remarks || ""
  ];

  deliverySheet.appendRow(row);
  return responseJSON(true, "Delivery completed successfully", { deliveryId: deliveryId });
}

function handleUpdateInventory(payload) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Inventory");

  const row = [
    new Date(),
    payload.totalCans || 500,
    payload.filledCans || 280,
    payload.emptyCans || 120,
    payload.damagedCans || 10,
    payload.customerBalanceCans || 90,
    payload.filledCans || 280
  ];

  sheet.appendRow(row);
  return responseJSON(true, "Inventory updated", payload);
}

function handleAddWaterPurchase(payload) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("WaterPurchase");

  const purchaseId = "WP-" + (1000 + sheet.getLastRow());
  const row = [
    purchaseId,
    payload.plantName || "Aqua Plant",
    new Date(),
    payload.cansPurchased || 0,
    payload.costPerCan || 15.0,
    payload.totalCost || 0.0,
    payload.notes || ""
  ];

  sheet.appendRow(row);
  return responseJSON(true, "Water purchase recorded", { purchaseId: purchaseId });
}

function handleSaveEmployee(payload) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Employees");
  const empId = payload.id || ("EMP-" + (1000 + sheet.getLastRow()));

  const row = [
    empId,
    payload.name,
    payload.username || payload.name.toLowerCase().replace(/\s+/g, ''),
    payload.password || "pass123",
    payload.role || "Delivery Boy",
    payload.phone || "",
    payload.baseSalary || 15000.0,
    "Active"
  ];

  sheet.appendRow(row);
  return responseJSON(true, "Employee saved", { employeeId: empId });
}

function handleAddExpense(payload) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Expenses");

  const expenseId = "EXP-" + (1000 + sheet.getLastRow());
  const row = [
    expenseId,
    new Date(),
    payload.category || "Miscellaneous",
    payload.description || "",
    payload.amount || 0.0,
    payload.spentBy || "Admin"
  ];

  sheet.appendRow(row);
  return responseJSON(true, "Expense logged", { expenseId: expenseId });
}

function handleRecordPayment(payload) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Payments");

  const paymentId = "PAY-" + (1000 + sheet.getLastRow());
  const row = [
    paymentId,
    payload.customerId,
    payload.orderId || "",
    payload.amount || 0.0,
    payload.paymentMode || "Cash",
    new Date(),
    "Completed"
  ];

  sheet.appendRow(row);
  return responseJSON(true, "Payment recorded", { paymentId: paymentId });
}

function handleRecalculateDashboard() {
  const metrics = calculateDashboardMetrics();
  return responseJSON(true, "Dashboard calculated", metrics);
}

function calculateDashboardMetrics() {
  const orders = getSheetData("Orders");
  const expenses = getSheetData("Expenses");
  const customers = getSheetData("Customers");

  let revenue = 0;
  let totalExpenses = 0;
  let pendingDues = 0;

  orders.forEach(o => {
    revenue += Number(o.TotalAmount || 0);
  });

  expenses.forEach(e => {
    totalExpenses += Number(e.Amount || 0);
  });

  customers.forEach(c => {
    pendingDues += Number(c.PendingAmount || 0);
  });

  return {
    todayOrders: orders.length,
    revenue: revenue,
    expenses: totalExpenses,
    netProfit: revenue - totalExpenses,
    pendingPayments: pendingDues,
    lastUpdated: new Date()
  };
}

// --- HELPER UTILITIES ---

function getSheetData(sheetName) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  const result = [];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const obj = {};
    for (let j = 0; j < headers.length; j++) {
      obj[headers[j]] = row[j];
    }
    result.push(obj);
  }
  return result;
}

function responseJSON(success, message, data) {
  const output = {
    success: success,
    message: message,
    data: data
  };
  return ContentService.createTextOutput(JSON.stringify(output))
    .setMimeType(ContentService.MimeType.JSON);
}
