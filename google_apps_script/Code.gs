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

/**
 * Setup database tabs and headers safely.
 * Creates missing sheets and adds missing columns without deleting existing data.
 */
function setupDatabase() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  for (const sheetName in SHEETS_SCHEMA) {
    const requiredHeaders = SHEETS_SCHEMA[sheetName];
    ensureSheetExists(ss, sheetName, requiredHeaders);
  }
}

/**
 * Ensures a sheet exists and contains all required headers.
 * Keeps existing data safe and appends missing columns if needed.
 */
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

/**
 * Formats header row: bold text, cyan background (#1DAEFF), white text, frozen row 1, auto filter.
 */
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

    // Step 1: Extract action from query parameters or form fields
    if (e && e.parameter && e.parameter.action) {
      action = e.parameter.action.toString().trim();
    }

    // Step 2: Extract payload from form fields (e.parameter.payload) or raw body (e.postData.contents)
    if (e && e.parameter && e.parameter.payload) {
      try {
        payload = JSON.parse(e.parameter.payload);
      } catch (_) {
        payload = e.parameter;
      }
    } else if (e && e.postData && e.postData.contents) {
      try {
        const request = JSON.parse(e.postData.contents);
        if (!action) action = (request.action || "").toString().trim();
        payload = request.payload || request;
      } catch (err) {
        if (!action && e.parameter && e.parameter.action) {
          action = e.parameter.action.toString().trim();
        }
        payload = e.parameter || {};
      }
    } else if (e && e.parameter) {
      payload = e.parameter || {};
    }

    // Step 3: Normalize action (strip leading slash if present)
    if (action.startsWith("/")) {
      action = action.substring(1);
    }

    if (!action) {
      return responseJSON(false, "Invalid request payload - Action missing", null);
    }

    switch (action) {
      case "login":
        return handleLogin(payload);

      // Customers
      case "customers":
      case "saveCustomer":
        return handleSaveCustomer(payload);
      case "deleteCustomer":
        return handleDeleteItem("Customers", "CustomerID", payload.id || payload.customerId);

      // Orders
      case "orders":
      case "createOrder":
        return handleCreateOrder(payload);
      case "updateOrder":
      case "updateOrderStatus":
        return handleUpdateOrder(payload);
      case "deleteOrder":
        return handleDeleteItem("Orders", "OrderID", payload.id || payload.orderId);

      // Delivery
      case "delivery":
      case "completeDelivery":
        return handleCompleteDelivery(payload);

      // Inventory
      case "inventory":
      case "updateInventory":
        return handleUpdateInventory(payload);

      // Water Purchase
      case "waterPurchase":
      case "addWaterPurchase":
        return handleAddWaterPurchase(payload);

      // Employees
      case "employees":
      case "saveEmployee":
        return handleSaveEmployee(payload);
      case "deleteEmployee":
        return handleDeleteItem("Employees", "EmployeeID", payload.id || payload.employeeId);

      // Expenses
      case "expenses":
      case "addExpense":
        return handleAddExpense(payload);

      // Payments
      case "payments":
      case "recordPayment":
        return handleRecordPayment(payload);

      // --- FINANCE MODULE ENDPOINTS ---

      // Income
      case "income":
      case "saveIncome":
        return handleSaveIncome(payload);
      case "deleteIncome":
        return handleDeleteItem("Income", "IncomeID", payload.id || payload.incomeId);

      // Deposits
      case "deposits":
      case "saveDeposit":
        return handleSaveDeposit(payload);
      case "refundDeposit":
        return handleRefundDeposit(payload);

      // Investments
      case "investments":
      case "saveInvestment":
        return handleSaveInvestment(payload);

      // Can Purchase
      case "canPurchase":
      case "addCanPurchase":
        return handleAddCanPurchase(payload);

      // Transactions
      case "transactions":
      case "addTransaction":
        return handleAddTransaction(payload);

      // Assets
      case "assets":
      case "saveAsset":
        return handleSaveAsset(payload);

      // Reports & Settings & Dashboard
      case "reports":
      case "addReport":
        return handleAddReport(payload);
      case "settings":
      case "saveSetting":
        return handleSaveSetting(payload);
      case "dashboard":
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

      // Finance GET Endpoints
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
        return responseJSON(true, "Profit & Loss records fetched", getSheetData("ProfitLoss"));
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

// --- HANDLER IMPLEMENTATIONS ---

function handleLogin(payload) {
  const username = (payload.username || "").toString().trim().toLowerCase();
  const password = (payload.password || "").toString().trim();

  if (!username || !password) {
    return responseJSON(false, "Username and password are required", null);
  }

  if ((username === "admin" || username === "puredrop") && password === "admin123") {
    return responseJSON(true, "Login successful", {
      employeeId: "ADM-001",
      name: "Pure Drop Admin",
      username: "admin",
      role: "Admin",
      status: "Active"
    });
  }

  if ((username === "driver" || username === "ramesh") && password === "driver123") {
    return responseJSON(true, "Login successful", {
      employeeId: "DRV-101",
      name: "Ramesh Kumar",
      username: "driver",
      role: "Delivery Boy",
      status: "Active"
    });
  }

  const employees = getSheetData("Employees");
  const found = employees.find(emp => 
    (emp.Username || emp.EmployeeName || "").toString().trim().toLowerCase() === username
  );

  if (found) {
    return responseJSON(true, "Login successful", found);
  }

  return responseJSON(false, "Invalid username or password", null);
}

function handleSaveCustomer(payload) {
  if (!payload.name && !payload.customerName) {
    return responseJSON(false, "Customer Name is required", null);
  }

  const sheet = getSheet("Customers");
  const data = sheet.getDataRange().getValues();
  const headers = getHeaders("Customers");

  let customerId = payload.id || payload.customerId || "";
  let rowIndex = -1;

  if (customerId) {
    for (let i = 1; i < data.length; i++) {
      if (String(data[i][0]) === String(customerId)) {
        rowIndex = i + 1;
        break;
      }
    }
  }

  if (!customerId) {
    customerId = "CUST-" + (1000 + data.length);
  }

  const rowObj = {
    "CustomerID": customerId,
    "CustomerName": payload.name || payload.customerName || "",
    "MobileNumber": payload.phone || payload.mobileNumber || "",
    "AlternativeNumber": payload.alternativePhone || payload.alternativeNumber || "",
    "Address": payload.address || "",
    "Area": payload.area || "",
    "Latitude": payload.latitude || 0.0,
    "Longitude": payload.longitude || 0.0,
    "SubscriptionType": payload.customerType || payload.subscriptionType || "Regular",
    "DepositAmount": payload.depositAmount || 0,
    "FilledCanBalance": payload.canBalance || payload.filledCanBalance || 0,
    "EmptyCanBalance": payload.emptyCanBalance || 0,
    "PendingAmount": payload.pendingDues || payload.pendingAmount || 0.0,
    "Status": payload.status || "Active",
    "CreatedDate": payload.createdDate || new Date().toISOString(),
    "LastDeliveryDate": payload.lastDeliveryDate || "",
    "NextDeliveryDate": payload.nextDeliveryDate || "",
    "Notes": payload.notes || ""
  };

  const rowArray = headers.map(h => rowObj[h] !== undefined ? rowObj[h] : "");

  if (rowIndex > 1) {
    sheet.getRange(rowIndex, 1, 1, rowArray.length).setValues([rowArray]);
  } else {
    sheet.appendRow(rowArray);
  }

  return responseJSON(true, "Customer saved successfully", { customerId: customerId, ...rowObj });
}

function handleCreateOrder(payload) {
  const sheet = getSheet("Orders");
  const headers = getHeaders("Orders");

  const orderId = payload.id || payload.orderId || ("ORD-" + (1000 + sheet.getLastRow()));
  const rowObj = {
    "OrderID": orderId,
    "CustomerID": payload.customerId || "",
    "CustomerName": payload.customerName || "",
    "OrderDate": payload.orderDate || new Date().toISOString(),
    "DeliveryDate": payload.deliveryDate || new Date().toISOString(),
    "FilledCans": payload.quantity || payload.filledCans || 1,
    "EmptyReturned": payload.emptyCansCollected || payload.emptyReturned || 0,
    "PricePerCan": payload.unitPrice || payload.pricePerCan || 35.0,
    "TotalAmount": payload.totalAmount || ((payload.quantity || 1) * (payload.unitPrice || 35.0)),
    "PaymentStatus": payload.paymentStatus || "pending",
    "DeliveryStatus": payload.status || payload.deliveryStatus || "pending",
    "AssignedDriver": payload.assignedDriverName || payload.assignedDriver || "",
    "CreatedBy": payload.createdBy || "Admin",
    "CreatedDate": new Date().toISOString()
  };

  const rowArray = headers.map(h => rowObj[h] !== undefined ? rowObj[h] : "");
  sheet.appendRow(rowArray);

  // Auto log transaction
  recordLedgerTransaction("Order Sales", Number(rowObj.TotalAmount), 0, orderId, payload.paymentMode || "Cash", "Order Created for " + rowObj.CustomerName);

  return responseJSON(true, "Order created successfully", { orderId: orderId, ...rowObj });
}

function handleUpdateOrder(payload) {
  const sheet = getSheet("Orders");
  const data = sheet.getDataRange().getValues();
  const headers = getHeaders("Orders");
  const idColIndex = headers.indexOf("OrderID");

  if (idColIndex === -1) return responseJSON(false, "OrderID header not found", null);

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][idColIndex]) === String(payload.id || payload.orderId)) {
      const pStatusCol = headers.indexOf("PaymentStatus");
      const dStatusCol = headers.indexOf("DeliveryStatus");
      const driverCol = headers.indexOf("AssignedDriver");

      if (pStatusCol !== -1 && payload.paymentStatus) sheet.getRange(i + 1, pStatusCol + 1).setValue(payload.paymentStatus);
      if (dStatusCol !== -1 && (payload.status || payload.deliveryStatus)) sheet.getRange(i + 1, dStatusCol + 1).setValue(payload.status || payload.deliveryStatus);
      if (driverCol !== -1 && (payload.assignedDriverName || payload.assignedDriver)) sheet.getRange(i + 1, driverCol + 1).setValue(payload.assignedDriverName || payload.assignedDriver);

      return responseJSON(true, "Order updated successfully", payload);
    }
  }
  return responseJSON(false, "Order ID not found", null);
}

function handleCompleteDelivery(payload) {
  const sheet = getSheet("Delivery");
  const headers = getHeaders("Delivery");
  const deliveryId = "DEL-" + (1000 + sheet.getLastRow());

  const rowObj = {
    "DeliveryID": deliveryId,
    "DriverName": payload.driverName || payload.assignedDriverName || "Driver",
    "CustomerID": payload.customerId || "",
    "CustomerName": payload.customerName || "",
    "Route": payload.route || payload.area || "",
    "DeliveryDate": new Date().toISOString(),
    "DeliveryStatus": payload.status || "Delivered",
    "PaymentCollected": payload.collectedPayment || payload.paymentCollected || 0.0,
    "EmptyCollected": payload.collectedEmpty || payload.emptyCollected || 0,
    "Remarks": payload.remarks || payload.notes || ""
  };

  const rowArray = headers.map(h => rowObj[h] !== undefined ? rowObj[h] : "");
  sheet.appendRow(rowArray);

  if (rowObj.PaymentCollected > 0) {
    recordLedgerTransaction("Delivery Collection", Number(rowObj.PaymentCollected), 0, deliveryId, "Cash/UPI", "Collection by " + rowObj.DriverName);
  }

  return responseJSON(true, "Delivery completed successfully", rowObj);
}

function handleUpdateInventory(payload) {
  const sheet = getSheet("Inventory");
  const headers = getHeaders("Inventory");
  const invId = "INV-" + (1000 + sheet.getLastRow());

  const rowObj = {
    "InventoryID": invId,
    "Date": new Date().toISOString(),
    "FilledCans": payload.filledCans || 0,
    "EmptyCans": payload.emptyCans || 0,
    "DamagedCans": payload.damagedCans || 0,
    "LostCans": payload.lostCans || 0,
    "AvailableStock": payload.filledCans || 0,
    "Remarks": payload.remarks || payload.notes || "Stock update"
  };

  const rowArray = headers.map(h => rowObj[h] !== undefined ? rowObj[h] : "");
  sheet.appendRow(rowArray);
  return responseJSON(true, "Inventory updated successfully", rowObj);
}

function handleAddWaterPurchase(payload) {
  const sheet = getSheet("WaterPurchase");
  const headers = getHeaders("WaterPurchase");
  const purchaseId = payload.id || ("WP-" + (1000 + sheet.getLastRow()));

  const rowObj = {
    "PurchaseID": purchaseId,
    "SupplierName": payload.plantName || payload.supplierName || "Aqua Plant",
    "PurchaseDate": payload.date || new Date().toISOString(),
    "Quantity": payload.cansPurchased || payload.quantity || 0,
    "PricePerCan": payload.costPerCan || payload.pricePerCan || 15.0,
    "TotalCost": payload.totalCost || (payload.cansPurchased * payload.costPerCan) || 0.0,
    "InvoiceNumber": payload.invoiceNumber || "",
    "Remarks": payload.notes || payload.remarks || ""
  };

  const rowArray = headers.map(h => rowObj[h] !== undefined ? rowObj[h] : "");
  sheet.appendRow(rowArray);

  recordLedgerTransaction("Water Purchase Expense", 0, Number(rowObj.TotalCost), purchaseId, "Bank Transfer", "Purchased from " + rowObj.SupplierName);

  return responseJSON(true, "Water purchase recorded successfully", rowObj);
}

function handleSaveEmployee(payload) {
  const sheet = getSheet("Employees");
  const headers = getHeaders("Employees");
  const empId = payload.id || ("EMP-" + (1000 + sheet.getLastRow()));

  const rowObj = {
    "EmployeeID": empId,
    "EmployeeName": payload.name || payload.employeeName || "",
    "Role": payload.role || "Delivery Boy",
    "Phone": payload.phone || "",
    "Salary": payload.baseSalary || payload.salary || 15000.0,
    "Address": payload.address || "",
    "Status": payload.status || "Active",
    "JoiningDate": payload.joiningDate || new Date().toISOString()
  };

  const rowArray = headers.map(h => rowObj[h] !== undefined ? rowObj[h] : "");
  sheet.appendRow(rowArray);
  return responseJSON(true, "Employee saved successfully", rowObj);
}

function handleAddExpense(payload) {
  const sheet = getSheet("Expenses");
  const headers = getHeaders("Expenses");
  const expenseId = payload.id || ("EXP-" + (1000 + sheet.getLastRow()));

  const rowObj = {
    "ExpenseID": expenseId,
    "ExpenseDate": payload.date || new Date().toISOString(),
    "Category": payload.category || "Miscellaneous",
    "Amount": payload.amount || 0.0,
    "Description": payload.description || "",
    "CreatedBy": payload.spentBy || payload.createdBy || "Admin"
  };

  const rowArray = headers.map(h => rowObj[h] !== undefined ? rowObj[h] : "");
  sheet.appendRow(rowArray);

  recordLedgerTransaction("Business Expense", 0, Number(rowObj.Amount), expenseId, "Cash/UPI", rowObj.Category + ": " + rowObj.Description);

  return responseJSON(true, "Expense logged successfully", rowObj);
}

function handleRecordPayment(payload) {
  const sheet = getSheet("Income");
  const headers = getHeaders("Income");
  const incomeId = "INC-" + (1000 + sheet.getLastRow());

  const rowObj = {
    "IncomeID": incomeId,
    "Date": new Date().toISOString(),
    "IncomeType": payload.incomeType || "Water Can Sales",
    "CustomerID": payload.customerId || "",
    "CustomerName": payload.customerName || "",
    "OrderID": payload.orderId || "",
    "Amount": payload.amount || 0.0,
    "PaymentMethod": payload.paymentMode || payload.paymentMethod || "Cash",
    "ReferenceNumber": payload.referenceNumber || "",
    "CollectedBy": payload.collectedBy || "Admin",
    "Status": "Completed",
    "Remarks": payload.remarks || "",
    "CreatedAt": new Date().toISOString()
  };

  sheet.appendRow(headers.map(h => rowObj[h] !== undefined ? rowObj[h] : ""));
  recordLedgerTransaction("Payment Received", Number(rowObj.Amount), 0, incomeId, rowObj.PaymentMethod, "Income: " + rowObj.IncomeType);

  return responseJSON(true, "Payment recorded successfully", rowObj);
}

// --- FINANCE MODULE HANDLERS ---

function handleSaveIncome(payload) {
  const sheet = getSheet("Income");
  const headers = getHeaders("Income");
  const incomeId = payload.id || ("INC-" + (1000 + sheet.getLastRow()));

  const rowObj = {
    "IncomeID": incomeId,
    "Date": payload.date || new Date().toISOString(),
    "IncomeType": payload.incomeType || "Water Can Sales",
    "CustomerID": payload.customerId || "",
    "CustomerName": payload.customerName || "",
    "OrderID": payload.orderId || "",
    "Amount": payload.amount || 0.0,
    "PaymentMethod": payload.paymentMethod || "Cash",
    "ReferenceNumber": payload.referenceNumber || "",
    "CollectedBy": payload.collectedBy || "Admin",
    "Status": payload.status || "Completed",
    "Remarks": payload.remarks || "",
    "CreatedAt": new Date().toISOString()
  };

  sheet.appendRow(headers.map(h => rowObj[h] !== undefined ? rowObj[h] : ""));
  recordLedgerTransaction("Income Received", Number(rowObj.Amount), 0, incomeId, rowObj.PaymentMethod, rowObj.IncomeType);

  return responseJSON(true, "Income logged successfully", rowObj);
}

function handleSaveDeposit(payload) {
  const sheet = getSheet("Deposits");
  const headers = getHeaders("Deposits");
  const depositId = payload.id || ("DEP-" + (1000 + sheet.getLastRow()));

  const depAmt = Number(payload.depositAmount || 0);
  const retAmt = Number(payload.returnedAmount || 0);
  const curBal = Math.max(0, depAmt - retAmt);

  const rowObj = {
    "DepositID": depositId,
    "CustomerID": payload.customerId || "",
    "CustomerName": payload.customerName || "",
    "DepositAmount": depAmt,
    "ReturnedAmount": retAmt,
    "CurrentBalance": curBal,
    "DepositDate": payload.depositDate || new Date().toISOString(),
    "ReturnDate": payload.returnDate || "",
    "Status": curBal > 0 ? "Active" : "Refunded",
    "Remarks": payload.remarks || ""
  };

  sheet.appendRow(headers.map(h => rowObj[h] !== undefined ? rowObj[h] : ""));
  recordLedgerTransaction("Customer Deposit Received", depAmt, retAmt, depositId, "Cash/Bank", "Deposit for " + rowObj.CustomerName);

  return responseJSON(true, "Deposit saved successfully", rowObj);
}

function handleRefundDeposit(payload) {
  const sheet = getSheet("Deposits");
  const data = sheet.getDataRange().getValues();
  const headers = getHeaders("Deposits");
  const depId = payload.depositId || payload.id;
  const refundAmt = Number(payload.refundAmount || 0);

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(depId)) {
      const currentRet = Number(data[i][4] || 0);
      const newRet = currentRet + refundAmt;
      const depAmt = Number(data[i][3] || 0);
      const newBal = Math.max(0, depAmt - newRet);

      sheet.getRange(i + 1, 5).setValue(newRet);
      sheet.getRange(i + 1, 6).setValue(newBal);
      sheet.getRange(i + 1, 8).setValue(new Date().toISOString());
      sheet.getRange(i + 1, 9).setValue(newBal === 0 ? "Refunded" : "Partial Refund");

      recordLedgerTransaction("Deposit Refund", 0, refundAmt, String(depId), "Cash/Bank", "Refund to " + data[i][2]);

      return responseJSON(true, "Deposit refunded successfully", { depositId: depId, refundAmount: refundAmt, currentBalance: newBal });
    }
  }
  return responseJSON(false, "Deposit record not found", null);
}

function handleSaveInvestment(payload) {
  const sheet = getSheet("Investments");
  const headers = getHeaders("Investments");
  const invId = payload.id || ("INV-EST-" + (1000 + sheet.getLastRow()));

  const rowObj = {
    "InvestmentID": invId,
    "Date": payload.date || new Date().toISOString(),
    "InvestorName": payload.investorName || "Owner",
    "InvestmentType": payload.investmentType || "Business Expansion",
    "Amount": payload.amount || 0.0,
    "Purpose": payload.purpose || "",
    "PaymentMethod": payload.paymentMethod || "Bank Transfer",
    "ReferenceNumber": payload.referenceNumber || "",
    "Remarks": payload.remarks || ""
  };

  sheet.appendRow(headers.map(h => rowObj[h] !== undefined ? rowObj[h] : ""));
  recordLedgerTransaction("Capital Investment", Number(rowObj.Amount), 0, invId, rowObj.PaymentMethod, "Investment by " + rowObj.InvestorName);

  return responseJSON(true, "Investment recorded successfully", rowObj);
}

function handleAddCanPurchase(payload) {
  const sheet = getSheet("CanPurchase");
  const headers = getHeaders("CanPurchase");
  const purId = payload.id || ("CAN-PUR-" + (1000 + sheet.getLastRow()));

  const qty = Number(payload.canQuantity || 0);
  const price = Number(payload.pricePerCan || 0);
  const gst = Number(payload.gst || 0);
  const transport = Number(payload.transportCost || 0);
  const other = Number(payload.otherCharges || 0);
  const total = (qty * price) + gst + transport + other;

  const rowObj = {
    "PurchaseID": purId,
    "SupplierName": payload.supplierName || "Can Supplier",
    "PurchaseDate": payload.purchaseDate || new Date().toISOString(),
    "CanQuantity": qty,
    "PricePerCan": price,
    "GST": gst,
    "TransportCost": transport,
    "OtherCharges": other,
    "TotalAmount": total,
    "InvoiceNumber": payload.invoiceNumber || "",
    "Remarks": payload.remarks || ""
  };

  sheet.appendRow(headers.map(h => rowObj[h] !== undefined ? rowObj[h] : ""));
  recordLedgerTransaction("New Can Purchase", 0, total, purId, "Bank Transfer", "Purchased " + qty + " new cans");

  // Automatically update Inventory stock
  updateCanPurchaseInventory(qty);

  return responseJSON(true, "Can purchase logged successfully", rowObj);
}

function updateCanPurchaseInventory(addedCans) {
  try {
    const sheet = getSheet("Inventory");
    const data = sheet.getDataRange().getValues();
    let currentTotal = 0, currentEmpty = 0, currentFilled = 0, currentDamaged = 0;

    if (data.length > 1) {
      const last = data[data.length - 1];
      currentFilled = Number(last[2] || 0);
      currentEmpty = Number(last[3] || 0);
      currentDamaged = Number(last[4] || 0);
    }

    currentEmpty += addedCans;
    const invId = "INV-" + (1000 + sheet.getLastRow());

    sheet.appendRow([
      invId,
      new Date().toISOString(),
      currentFilled,
      currentEmpty,
      currentDamaged,
      0,
      currentFilled,
      "Stock added from Can Purchase (+ " + addedCans + " cans)"
    ]);
  } catch (e) {
    Logger.log("Inventory update notice: " + e.toString());
  }
}

function handleAddTransaction(payload) {
  const sheet = getSheet("Transactions");
  const headers = getHeaders("Transactions");
  const txnId = payload.id || ("TXN-" + (1000 + sheet.getLastRow()));

  const data = sheet.getDataRange().getValues();
  let openingBal = 0.0;
  if (data.length > 1) {
    openingBal = Number(data[data.length - 1][6] || 0.0);
  }

  const credit = Number(payload.credit || 0.0);
  const debit = Number(payload.debit || 0.0);
  const closingBal = openingBal + credit - debit;

  const rowObj = {
    "TransactionID": txnId,
    "Date": payload.date || new Date().toISOString(),
    "TransactionType": payload.transactionType || "General",
    "Credit": credit,
    "Debit": debit,
    "OpeningBalance": openingBal,
    "ClosingBalance": closingBal,
    "ReferenceID": payload.referenceID || "",
    "PaymentMethod": payload.paymentMethod || "Cash",
    "Remarks": payload.remarks || ""
  };

  sheet.appendRow(headers.map(h => rowObj[h] !== undefined ? rowObj[h] : ""));
  return responseJSON(true, "Transaction recorded successfully", rowObj);
}

function recordLedgerTransaction(type, credit, debit, refId, paymentMethod, remarks) {
  try {
    handleAddTransaction({
      transactionType: type,
      credit: credit,
      debit: debit,
      referenceID: refId,
      paymentMethod: paymentMethod,
      remarks: remarks
    });
  } catch (e) {
    Logger.log("Ledger notice: " + e.toString());
  }
}

function handleSaveAsset(payload) {
  const sheet = getSheet("Assets");
  const headers = getHeaders("Assets");
  const assetId = payload.id || ("AST-" + (1000 + sheet.getLastRow()));

  const rowObj = {
    "AssetID": assetId,
    "AssetName": payload.assetName || "Company Asset",
    "Category": payload.category || "Equipment",
    "PurchaseDate": payload.purchaseDate || new Date().toISOString(),
    "PurchaseCost": payload.purchaseCost || 0.0,
    "CurrentValue": payload.currentValue || payload.purchaseCost || 0.0,
    "Status": payload.status || "Active",
    "Remarks": payload.remarks || ""
  };

  sheet.appendRow(headers.map(h => rowObj[h] !== undefined ? rowObj[h] : ""));
  return responseJSON(true, "Asset recorded successfully", rowObj);
}

function handleAddReport(payload) {
  const sheet = getSheet("Reports");
  const headers = getHeaders("Reports");
  const reportId = "REP-" + (1000 + sheet.getLastRow());

  const rowObj = {
    "ReportID": reportId,
    "ReportType": payload.reportType || "General Summary",
    "GeneratedDate": new Date().toISOString(),
    "GeneratedBy": payload.generatedBy || "Admin",
    "Summary": typeof payload.summary === 'object' ? JSON.stringify(payload.summary) : (payload.summary || "")
  };

  sheet.appendRow(headers.map(h => rowObj[h] !== undefined ? rowObj[h] : ""));
  return responseJSON(true, "Report saved successfully", rowObj);
}

function handleSaveSetting(payload) {
  const sheet = getSheet("Settings");
  const headers = getHeaders("Settings");
  const data = sheet.getDataRange().getValues();

  const key = payload.key || payload.settingKey || "";
  const val = payload.value || payload.settingValue || "";
  const desc = payload.description || "";

  if (!key) return responseJSON(false, "SettingKey is required", null);

  let rowIndex = -1;
  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(key)) {
      rowIndex = i + 1;
      break;
    }
  }

  const rowObj = { "SettingKey": key, "SettingValue": val, "Description": desc };
  const rowArray = headers.map(h => rowObj[h] !== undefined ? rowObj[h] : "");

  if (rowIndex > 1) {
    sheet.getRange(rowIndex, 1, 1, rowArray.length).setValues([rowArray]);
  } else {
    sheet.appendRow(rowArray);
  }

  return responseJSON(true, "Setting saved successfully", rowObj);
}

function handleDeleteItem(sheetName, idColumnName, idValue) {
  if (!idValue) return responseJSON(false, idColumnName + " is required for deletion", null);
  const sheet = getSheet(sheetName);
  if (!sheet) return responseJSON(false, "Sheet not found: " + sheetName, null);

  const data = sheet.getDataRange().getValues();
  const headers = getHeaders(sheetName);
  const idColIndex = headers.indexOf(idColumnName);

  if (idColIndex === -1) return responseJSON(false, "ID column " + idColumnName + " not found", null);

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][idColIndex]) === String(idValue)) {
      sheet.deleteRow(i + 1);
      return responseJSON(true, "Item deleted successfully from " + sheetName, { id: idValue });
    }
  }

  return responseJSON(false, "Item not found in " + sheetName + " with ID: " + idValue, null);
}

function handleRecalculateDashboard() {
  const metrics = calculateDashboardMetrics();
  return responseJSON(true, "Dashboard calculated successfully", metrics);
}

function calculateDashboardMetrics() {
  const orders = getSheetData("Orders");
  const expenses = getSheetData("Expenses");
  const customers = getSheetData("Customers");
  const income = getSheetData("Income");
  const deposits = getSheetData("Deposits");
  const investments = getSheetData("Investments");
  const canPurchases = getSheetData("CanPurchase");
  const assets = getSheetData("Assets");
  const inv = getSheetData("Inventory");

  let revenue = 0;
  let totalExpenses = 0;
  let pendingDues = 0;
  let totalIncome = 0;
  let totalDepositBalance = 0;
  let totalInvestment = 0;
  let totalCanPurchaseCost = 0;
  let totalAssetValue = 0;

  orders.forEach(o => revenue += Number(o.TotalAmount || 0));
  expenses.forEach(e => totalExpenses += Number(e.Amount || 0));
  customers.forEach(c => pendingDues += Number(c.PendingAmount || c.PendingDues || 0));
  income.forEach(inc => totalIncome += Number(inc.Amount || 0));
  deposits.forEach(d => totalDepositBalance += Number(d.CurrentBalance || 0));
  investments.forEach(inv => totalInvestment += Number(inv.Amount || 0));
  canPurchases.forEach(cp => totalCanPurchaseCost += Number(cp.TotalAmount || 0));
  assets.forEach(ast => totalAssetValue += Number(ast.CurrentValue || ast.PurchaseCost || 0));

  let filledStock = 0, emptyStock = 0;
  if (inv.length > 0) {
    const last = inv[inv.length - 1];
    filledStock = Number(last.FilledCans || 0);
    emptyStock = Number(last.EmptyCans || 0);
  }

  const netProfit = (revenue + totalIncome) - (totalExpenses + totalCanPurchaseCost);
  const netLoss = netProfit < 0 ? Math.abs(netProfit) : 0;
  const cashBalance = (revenue + totalIncome + totalInvestment + totalDepositBalance) - (totalExpenses + totalCanPurchaseCost);

  return {
    todaySales: revenue,
    todayCollection: revenue,
    monthlyRevenue: revenue + totalIncome,
    monthlyExpenses: totalExpenses,
    netProfit: netProfit,
    netLoss: netLoss,
    pendingPayments: pendingDues,
    outstandingAmount: pendingDues,
    totalDepositBalance: totalDepositBalance,
    totalInvestment: totalInvestment,
    totalCanPurchaseCost: totalCanPurchaseCost,
    currentCashBalance: cashBalance,
    availableFilledCans: filledStock,
    availableEmptyCans: emptyStock,
    businessAssetsValue: totalAssetValue,
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

  const headers = data[0].map(h => h.toString().trim());
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
