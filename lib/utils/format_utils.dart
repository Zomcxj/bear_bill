/// 金额格式化工具
class FormatUtils {
  /// 格式化金额：始终保留两位小数
  static String formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  /// 格式化金额，添加千分位
  static String formatAmountWithComma(double amount) {
    if (amount == amount.roundToDouble()) {
      return _addCommas(amount.toStringAsFixed(0));
    }
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = _addCommas(parts[0]);
    // 去掉末尾 0
    String dec = parts[1];
    if (dec.endsWith('0')) dec = dec.substring(0, dec.length - 1);
    return '$intPart.$dec';
  }

  /// 格式化金额显示（带符号）
  static String formatAmountWithSign(double amount, {String type = 'expense'}) {
    final formatted = formatAmount(amount);
    if (type == 'income') {
      return '+$formatted';
    } else {
      return '-$formatted';
    }
  }

  /// 处理金额输入（防止非法字符）
  static String handleAmountInput(String current, String key) {
    if (key == '⌫') {
      // 删除
      if (current.isEmpty) return current;
      return current.substring(0, current.length - 1);
    } else if (key == '.') {
      // 小数点
      if (current.contains('.')) return current;
      if (current.isEmpty) return '0.';
      return '$current.';
    } else if (key == '00') {
      // 双零
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
      // 数字
      if (current == '0' && key != '.') {
        return key;
      }
      // 限制最大长度
      if (current.length >= 10) return current;
      return '$current$key';
    }
  }

  /// 添加千分位逗号
  static String _addCommas(String str) {
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(regex, (match) => '${match[1]},');
  }

  /// 计算百分比
  static double calculatePercentage(double part, double total) {
    if (total == 0) return 0.0;
    return ((part / total) * 100).clamp(0.0, 100.0);
  }

  /// 格式化百分比：整数不显示小数
  static String formatPercentage(double percentage) {
    if (percentage == percentage.roundToDouble()) {
      return '${percentage.toInt()}%';
    }
    return '${percentage.toStringAsFixed(1)}%';
  }
}
