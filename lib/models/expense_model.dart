import '../core/constants/app_enums.dart';

class ExpenseModel {
  final String id;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final String spentBy;
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.spentBy,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'amount': amount,
        'description': description,
        'spentBy': spentBy,
        'date': date.toIso8601String(),
      };

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id'] ?? '',
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ExpenseCategory.miscellaneous,
        ),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] ?? '',
        spentBy: json['spentBy'] ?? 'Admin',
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
      );
}
