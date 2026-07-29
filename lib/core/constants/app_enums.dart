enum UserRole {
  admin,
  deliveryBoy;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.deliveryBoy:
        return 'Delivery Boy';
    }
  }
}

enum OrderStatus {
  pending,
  assigned,
  inTransit,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum PaymentStatus {
  paid,
  pending,
  partiallyPaid;

  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending Dues';
      case PaymentStatus.partiallyPaid:
        return 'Partial';
    }
  }
}

enum PaymentMode {
  cash,
  upi,
  bankTransfer,
  credit;

  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI / Online';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.credit:
        return 'Credit / Pending';
    }
  }
}

enum ExpenseCategory {
  waterPurchase,
  petrol,
  tea,
  snacks,
  salary,
  vehicleService,
  maintenance,
  canPurchase,
  miscellaneous;

  String get displayName {
    switch (this) {
      case ExpenseCategory.waterPurchase:
        return 'Water Purchase';
      case ExpenseCategory.petrol:
        return 'Petrol / Fuel';
      case ExpenseCategory.tea:
        return 'Tea';
      case ExpenseCategory.snacks:
        return 'Snacks & Food';
      case ExpenseCategory.salary:
        return 'Staff Salary';
      case ExpenseCategory.vehicleService:
        return 'Vehicle Service';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.canPurchase:
        return 'Can Purchase';
      case ExpenseCategory.miscellaneous:
        return 'Miscellaneous';
    }
  }
}

enum SyncStatus {
  synced,
  pending,
  syncing,
  error;
}
