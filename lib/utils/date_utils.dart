/// 日期工具类
class DateUtils {
  /// 格式化日期为 YYYY-MM-DD
  static String formatDate(DateTime date) {
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  /// 格式化日期为 YYYY-MM
  static String formatMonth(DateTime date) {
    return '${date.year}-${_pad(date.month)}';
  }

  /// 获取当前月份字符串
  static String getCurrentMonth() {
    return formatMonth(DateTime.now());
  }

  /// 获取今天日期字符串
  static String getToday() {
    return formatDate(DateTime.now());
  }

  /// 获取昨天日期字符串
  static String getYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return formatDate(yesterday);
  }

  /// 中文月份格式：2024年1月
  static String formatMonthCN(String month) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final mon = int.parse(parts[1]);
    return '$year年$mon月';
  }

  /// 中文日期格式：1月15日
  static String formatDayCN(String date) {
    final parts = date.split('-');
    final mon = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return '$mon月$day日';
  }

  /// 星期几
  static String getWeekday(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  /// 时段问候语
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

  /// 解析日期字符串
  static DateTime parseDate(String dateStr) {
    return DateTime.parse(dateStr);
  }

  /// 计算两个日期之间的天数差
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// 补零
  static String _pad(int n) {
    return n.toString().padLeft(2, '0');
  }
}
