# Pure Drop Aqua ERP 💧

**Pure Drop Aqua** is a comprehensive, modern Water Delivery & Inventory Management System built with **Flutter**, **Riverpod**, and **Hive NoSQL Local Storage**. It is designed specifically for water distribution businesses to manage customers, orders, inventory stock, plant purchases, driver deliveries, employee salaries, and financial analytics efficiently.

---

## 🎯 Current Project Status & Completed Features

The application is **fully functional** as an offline-first enterprise app with complete state management using Riverpod.

### ✅ Completed Modules

1. 🔐 **Authentication & Role-Based Access**
   - Separate access views for **Admin** and **Delivery Boy / Driver**.
   - Offline session persistence (`remember me`).
   - Quick role switcher for demo & testing.

2. 📊 **Analytics Dashboard**
   - Real-time today's orders count, revenue, total income, total expenses, and net profit.
   - 7-day revenue vs expense trend charts.
   - Live inventory status overview (Filled, Empty, Damaged, Customer balance cans).

3. 👥 **Customer Management**
   - Complete CRM: Add, Edit, Filter, and Delete customers.
   - Live tracking of can balances & pending dues per customer.
   - One-touch phone call & WhatsApp communication.
   - Address and route tagging.

4. 📦 **Order Management System**
   - Create new orders with custom pricing and delivery dates.
   - Status workflow: `Pending` ➔ `In Transit` ➔ `Delivered` / `Cancelled`.
   - Driver assignment & delivery dispatching.
   - Auto-updating inventory stock and customer dues upon delivery completion.

5. 🚚 **Driver Delivery App**
   - Streamlined interface for delivery personnel.
   - Mark deliveries as complete, collect empty cans, record damaged cans, and log payments on the spot.

6. 🏬 **Inventory & Can Tracking**
   - Real-time stock counts: Filled Cans, Empty Cans in Godown, Damaged Cans, and Cans with Customers.
   - Manual adjustment options for stock auditing.

7. 💧 **Plant Water Purchase Management**
   - Record bulk water purchases from plant suppliers.
   - Automatically increments filled can inventory and logs expenses.

8. 💰 **Expense & Payment Management**
   - Categorized expense tracking (Fuel, Vehicle Maintenance, Plant Water, Rent, Salary, Misc).
   - Customer payment collection tracking against pending dues.

9. 👷 **Employee & Salary System**
   - Staff directory with roles (Driver, Helper, Manager).
   - Monthly salary payout recorder with automatic financial expense entry.

10. ⚙️ **System & Offline Storage**
    - High-performance **Hive NoSQL local database**.
    - Complete data reset and database management tools in Settings.
    - Web & Desktop responsive layout compatibility.

---

## 📋 Requirements Needed From User to Reach 100% Production Launch

To finalize the app for actual business operations and publish it to the Google Play Store / App Store, please provide the following details and requirements:

### 1️⃣ Branding & Business Details
- [ ] **High-Resolution Logo**: High quality PNG / SVG logo files for App Icon and Invoices.
- [ ] **Business Information**: Official Business Name, Phone Numbers, Email, Address, and GSTIN (if applicable for invoices).
- [ ] **Default Price Rules**: Standard sale price per can (e.g., ₹35) and plant purchase cost per can (e.g., ₹15).

### 2️⃣ Cloud Backend & Multi-Device Sync Preference
Currently, the app works **100% offline on a single device**. If you need multiple devices (e.g., Admin phone + 3 Driver phones) to sync data live over the internet:
- [ ] **Backend Decision**:
  - Option A: **Firebase / Supabase** (Recommended for fast real-time cloud sync).
  - Option B: **Custom REST API / Node.js Backend**.
- [ ] **Cloud Account Access**: Firebase Project credentials or API Server URL.

### 3️⃣ Integrations (Optional but Recommended)
- [ ] **WhatsApp & SMS Gateway**: API key (e.g., Fast2SMS / Twilio) if you want automatic SMS/WhatsApp bills sent to customers on delivery.
- [ ] **Payment Gateway**: Razorpay / PhonePe API credentials or Business UPI QR code to accept online payments.
- [ ] **Google Maps API Key**: If live GPS route navigation and customer location mapping on Google Maps is required.

### 4️⃣ Play Store / App Store Deployment Requirements
- [ ] **Google Play Console Account**: Developer account access for publishing Android APK / AAB.
- [ ] **App Signing Key**: Keystore details for production release build.
- [ ] **Privacy Policy URL**: Required by Google Play Store guidelines.

---

## 🛠️ How to Run the Project Locally

1. **Prerequisites**: Ensure Flutter SDK (v3.19+ recommended) is installed.
2. **Clone & Install Dependencies**:
   ```bash
   git clone https://github.com/mythilijaikumar2-crypto/pure-drop-app.git
   cd pure-drop-app
   flutter pub get
   ```
3. **Run on Connected Device**:
   ```bash
   # Run on Chrome Web
   flutter run -d chrome

   # Run on Windows Desktop
   flutter run -d windows

   # Run on Android Device / Emulator
   flutter run -d android
   ```

---

## 📂 Project Structure
```
lib/
├── core/              # Design system, theme, widgets, local storage (Hive), constants
├── models/            # Data models (Customer, Order, Inventory, Expense, Employee, etc.)
├── providers/         # Riverpod state management & business logic
├── repositories/      # Offline repository layer (Hive data access)
├── routes/            # App navigation & router
└── features/          # App modules (Auth, Dashboard, Customer, Order, Delivery, etc.)
```

---

## 🤝 Next Action Plan

1. **Review this checklist** and let us know which features/integrations you would like to add next.
2. **Provide branding assets** (Logo & Details) to customize app UI and receipt print templates.
3. **Decide on Cloud Sync** (keep single-device offline vs. upgrade to multi-device live sync).
