# Pure Drop Aqua 💧

**Pure Drop Aqua** is an enterprise-grade Water Can Distribution Management System built with **Flutter**, **Riverpod**, **Hive NoSQL Database**, and **Google Firebase Cloud Services**.

---

## 🔄 End-to-End System Workflow

```mermaid
flowchart TD
    Start([1. Authentication]) --> AuthCheck{Role Check}
    AuthCheck -->|Admin / Super Admin| AdminDash[Admin Workspace Dashboard]
    AuthCheck -->|Delivery Boy| DriverDash[Driver Route Dashboard]

    subgraph Step 2: Customer Onboarding
        AdminDash --> AddCust[2. Add / Manage Customer Profile]
        AddCust --> CustSetup[Set Address, Can Price ₹35, Security Deposit ₹160, Maps Pin]
    end

    subgraph Step 3: Plant Water Purchases
        AdminDash --> PlantPurchase[3. Refill Filled Cans from Plant]
        PlantPurchase --> UpdateStock[Filled Cans +Qty | Log Plant Purchase Expense]
    end

    subgraph Step 4: Order Creation & Dispatch
        AdminDash --> CreateOrd[4. Create Order / Subscription]
        CreateOrd --> OrdTypes[Regular / Express Priority ⚡ / Recurring 🔄]
        OrdTypes --> AssignDriver[Assign Delivery Driver]
    end

    subgraph Step 5: Delivery Execution
        DriverDash --> ViewRoute[5. View Assigned Route]
        AssignDriver --> ViewRoute
        ViewRoute --> MapNav[Google Maps Route Navigation]
        MapNav --> CompleteDel[Complete Delivery & Proof Verification]
        CompleteDel --> CollectEmpty[Collect Returned Empty Cans & Record Damaged]
    end

    subgraph Step 6: Automated Ledger & Stock Sync
        CompleteDel --> AutoSync[6. Automatic System Update]
        AutoSync --> UpdateInv[Inventory: -Filled Cans, +Empty Cans]
        AutoSync --> UpdateCustLedger[Customer Ledger: +Active Cans, +Pending Dues, +Empty Cans Pending]
    end

    subgraph Step 7: Payment & PDF Invoicing
        AdminDash & DriverDash --> RecordPay[7. Record Payment Collection]
        RecordPay --> PayModes[Cash / UPI / Bank Transfer]
        PayModes --> GenPDF[Generate & Print PDF Invoice Receipt]
        GenPDF --> ClearDues[Deduct Customer Dues]
    end

    subgraph Step 8: Expenses & HR Payroll
        AdminDash --> LogExp[8. Log Expenses & Payroll]
        LogExp --> StaffSalary[Process Staff Salary & Print PDF Payslips]
    end

    subgraph Step 9: Analytics & Data Export
        AdminDash --> Analytics[9. Business Analytics & P&L Statement]
        Analytics --> ExportPDF[Export Executive PDF Summary]
        Analytics --> ExportCSV[Backup Database to Excel / CSV]
    end
```

---

## 📜 Complete Step-by-Step Workflow Guide

### 1. 🔐 System Authentication & RBAC
- **Login Credentials**:
  - **Admin Access**: User `admin` / Password `admin123` (Full system access across all modules).
  - **Delivery Staff Access**: User `driver` / Password `driver123` (Route-focused mobile view).
- **Session Security**: Offline session persistence (`Remember Me`) backed by Hive NoSQL storage with Firebase Auth integration.

### 2. 👥 Customer Management & Security Deposit
- **Profile Configuration**:
  - Add customers with name, phone, WhatsApp direct link, address, and **Google Maps Location Coordinates**.
  - **Security Deposit**: Automatically configured with default **₹160** stored inside customer profile.
  - Custom water can unit price configuration (default **₹35/can**).
- **Customer Ledger View**:
  - 3-Tab interactive drawer showing *Profile & Balance*, *Delivery History*, and *Payment History*.
  - Real-time balances: **Active Water Cans**, **Empty Cans Pending**, and **Pending Dues**.

### 3. 🏬 Plant Refill & Stock Management
- **Plant Purchases**:
  - Log batch refills of filled cans directly from water purification plants.
  - Automatically updates **Filled Cans Stock** and records purchase cost into the financial expense ledger.
- **Stock Audit & Alerts**:
  - Live counts: Filled Cans, Empty Cans in Plant, Damaged Cans, Lost Cans, and Cans with Customers.
  - Automatic **Low Stock Alert Banner** when filled cans drop below safety threshold.

### 4. 📦 Order Processing & Subscription Dispatch
- **Order Types**:
  - **Standard Order**: Immediate or scheduled water can delivery.
  - **Express Priority Order (⚡)**: Highlighted priority badge for rush deliveries.
  - **Recurring Subscriptions (🔄)**: Auto-recurring schedules (Daily, Weekly, Monthly).
- **Driver Dispatch**:
  - Assign pending orders to specific delivery personnel.

### 5. 🚚 Delivery Execution & Verification
- **Driver Dispatch Interface**:
  - Drivers view assigned route orders with direct phone call launcher and one-touch **Google Maps Route Navigation**.
- **Delivery Proof & Completion**:
  - Delivery modal supports OTP verification, signature proof, and photo proof.
  - Records delivered filled cans, returned empty cans, damaged cans, and collected payment mode.

### 6. ⚙️ Automated System Reconciliation
- Upon marking an order as **Delivered**, the system automatically performs atomic updates across database collections:
  - **Inventory**: Decreases Filled Cans, increases Empty Cans at plant.
  - **Customer Profile**: Increments Active Cans held, updates Empty Cans Pending, and adds total amount to Pending Dues.

### 7. 💳 Payment Collection & PDF Invoices
- **Payment Processing**:
  - Record payments for water charges or security deposit clearances via Cash, UPI, or Bank Transfer.
  - Immediately updates customer pending dues balance.
- **PDF Receipt Generator**:
  - Embedded engine generates downloadable and printable **A5 PDF Invoice Receipts** via `pdf` & `printing` packages.

### 8. 💸 Expense Management & HR Payroll
- **Expense Categorization**:
  - Log operational expenses (Fuel, Vehicle Maintenance, Plant Water, Office Expenses, Tea/Food, Misc).
- **Employee & Salary Payroll**:
  - Track employee directory, mark attendance, and calculate monthly salary payouts (Base salary + Incentives - Advances).
  - Generate printable **PDF Salary Slips**.

### 9. 📈 Executive Analytics & Data Export
- **Business Dashboard**:
  - Real-time KPIs: Revenue, Expenses, Net Profit ($$\text{Revenue} - \text{Plant Costs} - \text{Expenses} = \text{Net Profit}$$), Pending Dues, Delivered Orders Count.
  - Interactive 7-day revenue vs expense trend bar chart.
- **Data Export & Reporting**:
  - One-click **Executive PDF Summary Report** generation.
  - Export complete database or individual collections to **Excel / CSV** files.

---

## 🔥 Firebase Integration & Technical Audit Report

### ✅ 1. Features Working Perfectly (Working Status)

| Firebase Feature | Implementation File | Current Working Status |
| :--- | :--- | :--- |
| **Firebase Core Initialization** | `main.dart` & `firebase_options.dart` | Initializes cleanly with Firebase Project ID `puredropaqua-369f6`. |
| **Cloud Firestore Real-time Sync** | `firebase_service.dart` | Atomic background push for all data mutations (`SetOptions(merge: true)`). |
| **Offline Sync Queue Engine** | `sync_queue_manager.dart` | Queues all offline CRUD operations in Hive NoSQL and automatically pushes to Firestore when connectivity resumes. |
| **Firestore Security Rules** | `firestore.rules` | Role-based security rules defined for `customers`, `orders`, `deliveries`, `inventory`, `payments`, `expenses`, `employees`, `salary`, `water_purchases`, `settings`. |
| **Google Authentication** | `auth_service.dart` & `auth_provider.dart` | Google OAuth sign-in flow implemented with silent local fallback session. |
| **Firebase Storage Service** | `storage_service.dart` | Cloud upload wrapper for bill attachments, signatures, and delivery photo proofs. |
| **Firebase Cloud Messaging (FCM)** | `notification_service.dart` | Push notification service initialized for background delivery & stock alerts. |

---

### ⚠️ 2. Potential Gotchas, Limitations & Production Checklist

1. **Security Rules Development Fallback Rule**:
   - **Current Behavior**: `firestore.rules` contains a development fallback rule (`allow read, write: if isAuthenticated() || true;`) on line 89 to prevent local developer blocking when testing offline or without direct Firebase Auth login.
   - **Production Requirement**: For strict commercial deployment, line 89 should be removed or restricted to `allow read, write: if isAuthenticated();` once all delivery personnel are registered in Firebase Auth.

2. **Offline Multi-Device Conflict Resolution**:
   - **Current Behavior**: `SyncQueueManager` processes queued offline items sequentially using a "Last-Write-Wins" policy (`SetOptions(merge: true)`).
   - **Gotcha**: If two users edit the exact same customer or inventory document offline at the same time, the device that syncs last will overwrite the document.

3. **Cloud Firestore Indexing for Complex Compound Queries**:
   - **Current Behavior**: The app avoids Firestore index errors by loading cached records into Hive and performing fast in-memory Dart filtering.
   - **Gotcha**: If direct raw Firestore queries with multiple `.where()` and `.orderBy()` clauses are executed via stream listeners instead of in-memory filtering, Composite Indexes must be generated in the Firebase Console.

4. **SHA-1 Fingerprint for Google Sign-In Release Builds**:
   - **Requirement**: Google Sign-In requires registering your keystore SHA-1 fingerprint in the Firebase Console Android App Settings before deploying production release APKs.

---

## 🛠️ Technology Stack

| Layer | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Frontend Framework** | [Flutter SDK 3.12+](https://flutter.dev) | Cross-Platform UI (Android & Web Admin) |
| **State Management** | [Flutter Riverpod 2.5+](https://riverpod.dev) | Reactive state management & business logic |
| **Offline Database** | [Hive NoSQL 2.2+](https://pub.dev/packages/hive_flutter) | Zero-latency local storage & offline cache |
| **Cloud Database** | [Cloud Firestore](https://firebase.google.com/docs/firestore) | Real-time multi-device cloud database |
| **Cloud Auth** | [Firebase Authentication](https://firebase.google.com/docs/auth) | Role-based authentication & route guards |
| **PDF & Printing** | [Pdf 3.10+](https://pub.dev/packages/pdf) & [Printing 5.13+](https://pub.dev/packages/printing) | PDF Invoice receipts & Executive report export |
| **Charts** | [FlChart 0.68+](https://pub.dev/packages/fl_chart) | Interactive revenue & expense charts |
| **Maps & Maps Link** | [Google Maps](https://pub.dev/packages/google_maps_flutter) & [URL Launcher](https://pub.dev/packages/url_launcher) | Route navigation & WhatsApp launcher |

---

## 📂 Codebase Directory Structure

```text
lib/
├── core/
│   ├── constants/       # App colors, enums, business constants
│   ├── services/        # Firebase Service & Connectivity Sync Queue
│   ├── storage/        # Hive NoSQL Local Storage Service
│   ├── theme/          # Material 3 light/dark app theme
│   ├── utils/          # Result<T> pattern, Date/Currency formatters, validators
│   └── widgets/        # Reusable cards, buttons, text fields, status badges
├── models/             # Business Data Models (Customer, Order, Inventory, Expense, Employee, Salary, Payment, Water Purchase)
├── providers/          # Riverpod state management & dashboard metrics calculations
├── repositories/       # Clean Architecture Repository pattern (Hive + Firestore Sync)
├── routes/             # GoRouter navigation & RBAC route guards
└── features/           # App Modules (Auth, Dashboard, Customer, Order, Delivery, Inventory, Water Purchase, Employee, Salary, Expense, Payment, Report, Settings)
```

---

## 🚀 Running the Application

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Launch Application**:
   ```bash
   # Launch Web Admin
   flutter run -d chrome

   # Launch Android Mobile App
   flutter run -d android
   ```
