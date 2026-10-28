/// Amount formatting utilities
class FormatUtils {
  /// Format an amount: always keep two decimal places
  static String formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  /// Format an amount with thousands separators
  static String formatAmountWithComma(double amount) {
    if (amount == amount.roundToDouble()) {
      return _addCommas(amount.toStringAsFixed(0));
    }
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = _addCommas(parts[0]);
    // Trim trailing zeros
    String dec = parts[1];
    if (dec.endsWith('0')) dec = dec.substring(0, dec.length - 1);
    return '$intPart.$dec';
  }

  /// Format an amount for display (with sign)
  static String formatAmountWithSign(double amount, {String type = 'expense'}) {
    final formatted = formatAmount(amount);
    if (type == 'income') {
      return '+$formatted';
    } else {
      return '-$formatted';
    }
  }

  /// Handle amount input (rejects invalid characters)
  static String handleAmountInput(String current, String key) {
    if (key == '⌫') {
      // Delete
      if (current.isEmpty) return current;
      return current.substring(0, current.length - 1);
    } else if (key == '.') {
      // Decimal point
      if (current.contains('.')) return current;
      if (current.isEmpty) return '0.';
      return '$current.';
    } else if (key == '00') {
      // Double zero
      if (current.isEmpty || current == '0') return current;
      if (current.contains('.')) {
        final parts = current.split('.');
        final decimal = parts.length > 1 ? parts[1] : '';
        if (decimal.length >= 2) return current;
        final nextDecimal = ('${decimal}00').substring(0, 2);
        return '${parts[0]}.$nextDecimal';
      }
      return '${current}00';
    } else {
      // Digit
      if (current == '0' && key != '.') {
        return key;
      }
      // Cap the maximum length
      if (current.length >= 10) return current;
      return '$current$key';
    }
  }

  /// Add thousands separators
  static String _addCommas(String str) {
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(regex, (match) => '${match[1]},');
  }

  /// Calculate a percentage
  static double calculatePercentage(double part, double total) {
    if (total == 0) return 0.0;
    return ((part / total) * 100).clamp(0.0, 100.0);
  }

  /// Format a percentage: whole numbers hide the decimal part
  static String formatPercentage(double percentage) {
    if (percentage == percentage.roundToDouble()) {
      return '${percentage.toInt()}%';
    }
    return '${percentage.toStringAsFixed(1)}%';
  }
}
