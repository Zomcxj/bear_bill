/// Date utilities
class DateUtils {
  /// Format a date as YYYY-MM-DD
  static String formatDate(DateTime date) {
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  /// Format a date as YYYY-MM
  static String formatMonth(DateTime date) {
    return '${date.year}-${_pad(date.month)}';
  }

  /// Get the current month string
  static String getCurrentMonth() {
    return formatMonth(DateTime.now());
  }

  /// Get today's date string
  static String getToday() {
    return formatDate(DateTime.now());
  }

  /// Get yesterday's date string
  static String getYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return formatDate(yesterday);
  }

  /// Chinese month format, e.g. "2024年1月"
  static String formatMonthCN(String month) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final mon = int.parse(parts[1]);
    return '$year年$mon月';
  }

  /// Chinese date format, e.g. "1月15日"
  static String formatDayCN(String date) {
    final parts = date.split('-');
    final mon = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return '$mon月$day日';
  }

  /// Day of the week
  static String getWeekday(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  /// Time-of-day greeting
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '夜深了，今天的账单对齐了吗🌙';
    } else if (hour < 9) {
      return '早安呀～新的一天要开始啦🌸';
    } else if (hour < 12) {
      return '早上好！今天也要认真记账哦🐻';
    } else if (hour < 14) {
      return '午饭吃了什么好吃的～🍱';
    } else if (hour < 17) {
      return '下午好！喝杯奶茶记得记账哦🧋';
    } else if (hour < 19) {
      return '晚上好！今天收支怎么样呢🌙';
    } else {
      return '睡前看看账单，好梦相随🌛';
    }
  }

  /// Parse a date string
  static DateTime parseDate(String dateStr) {
    return DateTime.parse(dateStr);
  }

  /// Compute the number of days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Zero-pad
  static String _pad(int n) {
    return n.toString().padLeft(2, '0');
  }
}
