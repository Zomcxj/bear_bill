/// Utility function library
library;


/// Format an amount
String formatAmount(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
  }
  return amount.toStringAsFixed(2).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},'
  );
}

/// Format an amount (with sign)
String formatAmountWithSign(double amount, bool isExpense) {
  final sign = isExpense ? '-' : '+';
  return '$sign¥$amount';
}

/// Get the current month as YYYY-MM
String getCurrentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

/// Get today's date as YYYY-MM-DD
String getTodayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Format a date as YYYY-MM-DD
String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Format a month for display (Chinese)
String formatMonthCN(String month) {
  final parts = month.split('-');
  if (parts.length != 2) return month;
  return '${parts[0]}年${int.parse(parts[1])}月';
}

/// Friendly date display (today, yesterday, etc.)
String formatDateFriendly(String dateStr) {
  final now = DateTime.now();
  final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  
  if (dateStr == today) return '今天';
  
  final yesterday = now.subtract(const Duration(days: 1));
  final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  if (dateStr == yesterdayStr) return '昨天';
  
  final parts = dateStr.split('-');
  return '${int.parse(parts[1])}月${int.parse(parts[2])}日';
}

/// Get the weekday
String getWeekday(String dateStr) {
  final parts = dateStr.split('-');
  final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  return weekdays[date.weekday % 7];
}

/// Month offset
String offsetMonth(String month, int offset) {
  final parts = month.split('-');
  var year = int.parse(parts[0]);
  var monthNum = int.parse(parts[1]);
  
  monthNum += offset;
  while (monthNum > 12) {
    monthNum -= 12;
    year++;
  }
  while (monthNum < 1) {
    monthNum += 12;
    year--;
  }
  
  return '$year-${monthNum.toString().padLeft(2, '0')}';
}

/// Amount input handling
String? handleAmountInput(String current, String key) {
  if (key == '⌫') {
    if (current.isEmpty) return null;
    return current.substring(0, current.length - 1);
  }
  
  if (key == '.') {
    if (current.contains('.')) return null;
    if (current.isEmpty) return '0.';
    return '$current.';
  }
  
  // Digit key
  if (current.contains('.')) {
    final parts = current.split('.');
    if (parts[1].length >= 2) return null; // At most 2 decimal places
    if (parts[1].isEmpty && key == '0') return '$current.';
  }
  
  // Prevent a leading zero (unless it is a decimal)
  if (current == '0' && key != '.' && key != '00') {
    return key;
  }
  
  return current + key;
}

/// Get the time-of-day greeting
String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) return '早安呀～新的一天要开始啦🌸';
  if (hour >= 11 && hour < 14) return '午饭吃了什么好吃的～🍱';
  if (hour >= 14 && hour < 18) return '下午好！喝杯奶茶记得记账哦🧋';
  if (hour >= 18 && hour < 22) return '晚上好！今天收支怎么样呢🌙';
  return '夜深了，今天的账单对齐了吗🌙';
}

/// Get the bear's mood from the balance
({String emoji, String mood}) getBearMood(double balance) {
  if (balance > 2000) return (emoji: '🥳', mood: '超级开心！结余好多呢');
  if (balance > 500) return (emoji: '😊', mood: '不错哦，继续加油！');
  if (balance > 0) return (emoji: '😌', mood: '基本平衡，小熊放心了');
  if (balance > -500) return (emoji: '😅', mood: '稍微超支了，要注意哦');
  return (emoji: '😢', mood: '超支啦！下次省着点吧');
}
