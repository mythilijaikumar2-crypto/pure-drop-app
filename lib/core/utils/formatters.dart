import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.currency(
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatCompactCurrency(double amount) {
    return _compactCurrencyFormat.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static String formatCanCount(int count) {
    return '$count ${count == 1 ? "Can" : "Cans"}';
  }
}
