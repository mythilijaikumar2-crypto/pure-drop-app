class SettingsModel {
  final double defaultWaterPrice;
  final double defaultBottlePrice;
  final double defaultSecurityDeposit;
  final String companyName;
  final String companyPhone;
  final String companyAddress;
  final String taxNumber;
  final String invoiceFooterNote;
  final bool enableOfflineSync;
  final bool enableFcmNotifications;
  final List<DateTime> deliveryOffDays;

  SettingsModel({
    this.defaultWaterPrice = 35.0,
    this.defaultBottlePrice = 150.0,
    this.defaultSecurityDeposit = 160.0,
    this.companyName = 'Pure Drop Aqua',
    this.companyPhone = '+91 98765 43210',
    this.companyAddress = '123 Water Works Avenue, Pure City',
    this.taxNumber = 'GSTIN33AABCU9603R1ZM',
    this.invoiceFooterNote = 'Pure Water for Healthy Living. Thank you for your business!',
    this.enableOfflineSync = true,
    this.enableFcmNotifications = true,
    this.deliveryOffDays = const [],
  });

  Map<String, dynamic> toJson() => {
        'defaultWaterPrice': defaultWaterPrice,
        'defaultBottlePrice': defaultBottlePrice,
        'defaultSecurityDeposit': defaultSecurityDeposit,
        'companyName': companyName,
        'companyPhone': companyPhone,
        'companyAddress': companyAddress,
        'taxNumber': taxNumber,
        'invoiceFooterNote': invoiceFooterNote,
        'enableOfflineSync': enableOfflineSync,
        'enableFcmNotifications': enableFcmNotifications,
      };

  factory SettingsModel.fromJson(Map<String, dynamic> json) => SettingsModel(
        defaultWaterPrice: (json['defaultWaterPrice'] as num?)?.toDouble() ?? 35.0,
        defaultBottlePrice: (json['defaultBottlePrice'] as num?)?.toDouble() ?? 150.0,
        defaultSecurityDeposit: (json['defaultSecurityDeposit'] as num?)?.toDouble() ?? 160.0,
        companyName: json['companyName'] ?? 'Pure Drop Aqua',
        companyPhone: json['companyPhone'] ?? '+91 98765 43210',
        companyAddress: json['companyAddress'] ?? '123 Water Works Avenue, Pure City',
        taxNumber: json['taxNumber'] ?? 'GSTIN33AABCU9603R1ZM',
        invoiceFooterNote: json['invoiceFooterNote'] ?? 'Pure Water for Healthy Living.',
        enableOfflineSync: json['enableOfflineSync'] ?? true,
        enableFcmNotifications: json['enableFcmNotifications'] ?? true,
      );

  SettingsModel copyWith({
    double? defaultWaterPrice,
    double? defaultBottlePrice,
    double? defaultSecurityDeposit,
    String? companyName,
    String? companyPhone,
    String? companyAddress,
    String? taxNumber,
    String? invoiceFooterNote,
    bool? enableOfflineSync,
    bool? enableFcmNotifications,
  }) {
    return SettingsModel(
      defaultWaterPrice: defaultWaterPrice ?? this.defaultWaterPrice,
      defaultBottlePrice: defaultBottlePrice ?? this.defaultBottlePrice,
      defaultSecurityDeposit: defaultSecurityDeposit ?? this.defaultSecurityDeposit,
      companyName: companyName ?? this.companyName,
      companyPhone: companyPhone ?? this.companyPhone,
      companyAddress: companyAddress ?? this.companyAddress,
      taxNumber: taxNumber ?? this.taxNumber,
      invoiceFooterNote: invoiceFooterNote ?? this.invoiceFooterNote,
      enableOfflineSync: enableOfflineSync ?? this.enableOfflineSync,
      enableFcmNotifications: enableFcmNotifications ?? this.enableFcmNotifications,
    );
  }
}
