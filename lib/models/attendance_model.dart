class AttendanceModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final String status; // Present, Absent, HalfDay, Leave
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String notes;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.status = 'Present',
    this.checkInTime,
    this.checkOutTime,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'date': date.toIso8601String(),
        'status': status,
        'checkInTime': checkInTime?.toIso8601String(),
        'checkOutTime': checkOutTime?.toIso8601String(),
        'notes': notes,
      };

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => AttendanceModel(
        id: json['id'] ?? '',
        employeeId: json['employeeId'] ?? '',
        employeeName: json['employeeName'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        status: json['status'] ?? 'Present',
        checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
        checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
        notes: json['notes'] ?? '',
      );

  AttendanceModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? date,
    String? status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? notes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      notes: notes ?? this.notes,
    );
  }
}
