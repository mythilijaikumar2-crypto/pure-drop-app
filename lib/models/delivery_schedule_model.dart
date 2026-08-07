class DeliveryScheduleModel {
  final String id;
  final String customerId;
  final String customerName;
  final String frequency; // Daily, Alternate Days, Weekly, Monthly, Custom
  final List<int> daysOfWeek; // 1 = Mon ... 7 = Sun
  final int quantity;
  final double pricePerCan;
  final DateTime startDate;
  final DateTime? endDate;
  final String preferredTimeSlot; // Morning, Afternoon, Evening
  final bool isVacationActive;
  final DateTime? vacationStartDate;
  final DateTime? vacationEndDate;
  final DateTime? lastGeneratedDate;
  final bool isActive;

  DeliveryScheduleModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.frequency = 'Daily',
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.quantity = 1,
    this.pricePerCan = 35.0,
    required this.startDate,
    this.endDate,
    this.preferredTimeSlot = 'Morning',
    this.isVacationActive = false,
    this.vacationStartDate,
    this.vacationEndDate,
    this.lastGeneratedDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'frequency': frequency,
        'daysOfWeek': daysOfWeek,
        'quantity': quantity,
        'pricePerCan': pricePerCan,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'preferredTimeSlot': preferredTimeSlot,
        'isVacationActive': isVacationActive,
        'vacationStartDate': vacationStartDate?.toIso8601String(),
        'vacationEndDate': vacationEndDate?.toIso8601String(),
        'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
        'isActive': isActive,
      };

  factory DeliveryScheduleModel.fromJson(Map<String, dynamic> json) =>
      DeliveryScheduleModel(
        id: json['id'] ?? '',
        customerId: json['customerId'] ?? '',
        customerName: json['customerName'] ?? '',
        frequency: json['frequency'] ?? 'Daily',
        daysOfWeek: (json['daysOfWeek'] as List?)?.map((e) => e as int).toList() ??
            const [1, 2, 3, 4, 5, 6, 7],
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        pricePerCan: (json['pricePerCan'] as num?)?.toDouble() ?? 35.0,
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'])
            : DateTime.now(),
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        preferredTimeSlot: json['preferredTimeSlot'] ?? 'Morning',
        isVacationActive: json['isVacationActive'] ?? false,
        vacationStartDate: json['vacationStartDate'] != null
            ? DateTime.parse(json['vacationStartDate'])
            : null,
        vacationEndDate: json['vacationEndDate'] != null
            ? DateTime.parse(json['vacationEndDate'])
            : null,
        lastGeneratedDate: json['lastGeneratedDate'] != null
            ? DateTime.parse(json['lastGeneratedDate'])
            : null,
        isActive: json['isActive'] ?? true,
      );
}
