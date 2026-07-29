class SalaryModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String monthYear; // e.g. "July 2026"
  final double baseSalary;
  final double advances;
  final double bonus;
  final double netPayout;
  final DateTime payoutDate;
  final bool isPaid;

  SalaryModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.monthYear,
    required this.baseSalary,
    this.advances = 0.0,
    this.bonus = 0.0,
    required this.netPayout,
    required this.payoutDate,
    this.isPaid = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'monthYear': monthYear,
        'baseSalary': baseSalary,
        'advances': advances,
        'bonus': bonus,
        'netPayout': netPayout,
        'payoutDate': payoutDate.toIso8601String(),
        'isPaid': isPaid,
      };

  factory SalaryModel.fromJson(Map<String, dynamic> json) => SalaryModel(
        id: json['id'] ?? '',
        employeeId: json['employeeId'] ?? '',
        employeeName: json['employeeName'] ?? '',
        monthYear: json['monthYear'] ?? '',
        baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 0.0,
        advances: (json['advances'] as num?)?.toDouble() ?? 0.0,
        bonus: (json['bonus'] as num?)?.toDouble() ?? 0.0,
        netPayout: (json['netPayout'] as num?)?.toDouble() ?? 0.0,
        payoutDate: json['payoutDate'] != null
            ? DateTime.parse(json['payoutDate'])
            : DateTime.now(),
        isPaid: json['isPaid'] ?? true,
      );
}
