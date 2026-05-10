import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';

/// 全局应用状态管理 - Provider
class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  // 用户信息
  UserModel? _user;
  UserModel? get user => _user;

  // 当前账本
  String _currentBookId = '';
  String get currentBookId => _currentBookId;

  // 打卡状态
  int _checkInDays = 0;
  bool _todayChecked = false;
  int get checkInDays => _checkInDays;
  bool get todayChecked => _todayChecked;

  // 成就列表
  List<String> _unlockedAchievements = [];
  List<String> get unlockedAchievements => _unlockedAchievements;

  // 新解锁的成就（用于弹窗提示）
  List<AchievementModel> _newAchievements = [];
  List<AchievementModel> get newAchievements => _newAchievements;

  AppProvider() {
    _init();
  }

  /// 初始化 - 加载用户数据和状态
  Future<void> _init() async {
    await _loadUser();
    await _loadCheckInStatus();
    // 启动时检查升级（处理已有超额经验的情况）
    await levelUp();
    // 启动时同步检查所有成就
    await _syncAllAchievements();
  }

  /// 启动时同步所有成就状态
  Future<void> _syncAllAchievements() async {
    if (_user == null) return;

    final wishes = await _db.getAllWishes();
    final hasCreatedWish = wishes.isNotEmpty;
    final completedWishes = wishes.where((w) => w.isCompleted).length;

    final budgetStr = StorageService.instance.getString('monthlyBudget');
    final hasBudget = budgetStr != null && budgetStr.isNotEmpty && double.tryParse(budgetStr) != null && double.parse(budgetStr) > 0;

    final newAchievements = AchievementChecker.checkAllAchievements(
      checkInDays: _checkInDays,
      totalRecords: _user!.totalRecords,
      hasBudget: hasBudget,
      expenseRatio: 0,
      completedWishes: completedWishes,
      hasCreatedWish: hasCreatedWish,
      unlockedIds: _unlockedAchievements,
    );

    if (newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(newAchievements.map((a) => a.id));
      final updatedUser = _user!.copyWith(achievements: _unlockedAchievements);
      await _db.updateUser(updatedUser);
      _user = updatedUser;
      notifyListeners();
    }
  }

  /// 加载用户信息
  Future<void> _loadUser() async {
    _user = await _db.getDefaultUser();
    if (_user != null) {
      _currentBookId = _user!.defaultBookId;
      _checkInDays = _user!.checkInDays;
      _unlockedAchievements = List.from(_user!.achievements);

      // 如果数据库中打卡天数为0，尝试从文件缓存恢复
      if (_checkInDays == 0) {
        final cachedDays = StorageService.instance.getInt('checkInDays');
        if (cachedDays != null && cachedDays > 0) {
          _checkInDays = cachedDays;
          // 同步回数据库
          final updatedUser = _user!.copyWith(checkInDays: cachedDays);
          await _db.updateUser(updatedUser);
          _user = updatedUser;
        }
      }

      // 校准 totalRecords（修复历史虚高数据）
      try {
        final actualCount = await _db.getTotalRecordsCount();
        if (_user!.totalRecords != actualCount) {
          final fixed = _user!.copyWith(totalRecords: actualCount);
          await _db.updateUser(fixed);
          _user = fixed;
        }
      } catch (_) {}

      notifyListeners();
    }
  }

  /// 加载打卡状态
  Future<void> _loadCheckInStatus() async {
    final today = DateUtils.getToday();
    final lastCheckIn =
        StorageService.instance.getString('lastCheckInDate') ?? '';
    _todayChecked = (lastCheckIn == today);
    notifyListeners();
  }

  /// 切换账本
  Future<void> switchBook(String bookId) async {
    _currentBookId = bookId;
    StorageService.instance.setString('currentBookId', bookId);

    // 更新用户的默认账本
    if (_user != null) {
      final updatedUser = _user!.copyWith(defaultBookId: bookId);
      await _db.updateUser(updatedUser);
      _user = updatedUser;
    }

    notifyListeners();
  }

  /// 刷新当前账本信息（用于账本名称修改后）
  void refreshCurrentBook() {
    notifyListeners();
  }

  /// 记账后打卡
  Future<List<AchievementModel>> recordCheckIn() async {
    final today = DateUtils.getToday();
    final yesterday = DateUtils.getYesterday();
    final lastCheckIn =
        StorageService.instance.getString('lastCheckInDate') ?? '';

    if (lastCheckIn == today) {
      _todayChecked = true;
      notifyListeners();
      return [];
    }

    int newDays = _checkInDays;
    if (lastCheckIn == yesterday) {
      newDays += 1; // 连续打卡
    } else {
      newDays = 1; // 断签重计
    }

    StorageService.instance.setString('lastCheckInDate', today);
    StorageService.instance.setInt('checkInDays', newDays);

    _checkInDays = newDays;
    _todayChecked = true;

    // 更新用户数据
    if (_user != null) {
      final updatedUser = _user!.copyWith(
        checkInDays: newDays,
        lastCheckIn: today,
        exp: _user!.exp + 10, // 打卡获得10经验
      );
      await _db.updateUser(updatedUser);
      _user = updatedUser;
      await levelUp();
    }

    // 检查成就
    _newAchievements = AchievementChecker.checkCheckInAchievements(
      newDays,
      _unlockedAchievements,
    );

    if (_newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(_newAchievements.map((a) => a.id));
      if (_user != null) {
        final updatedUser =
            _user!.copyWith(achievements: _unlockedAchievements);
        await _db.updateUser(updatedUser);
        _user = updatedUser;
      }
    }

    notifyListeners();
    return _newAchievements;
  }

  /// 记账后更新统计
  Future<List<AchievementModel>> onRecordAdded({
    required String type,
    required double amount,
  }) async {
    if (_user == null) return [];

    final newTotalRecords = _user!.totalRecords + 1;
    final newExp = _user!.exp + 5; // 记账获得5经验

    final updatedUser = _user!.copyWith(
      totalRecords: newTotalRecords,
      exp: newExp,
    );
    await _db.updateUser(updatedUser);
    _user = updatedUser;
    await levelUp();

    // 检查成就
    _newAchievements = AchievementChecker.checkRecordsAchievements(
      newTotalRecords,
      _unlockedAchievements,
    );

    if (_newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(_newAchievements.map((a) => a.id));
      final finalUser = _user!.copyWith(achievements: _unlockedAchievements);
      await _db.updateUser(finalUser);
      _user = finalUser;
    }

    notifyListeners();
    return _newAchievements;
  }

  /// 删除记录后更新统计
  Future<void> onRecordDeleted() async {
    if (_user == null) return;

    final newTotal = (_user!.totalRecords - 1).clamp(0, 999999);
    final updatedUser = _user!.copyWith(totalRecords: newTotal);
    await _db.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  /// 清空新成就列表（弹窗关闭后调用）
  void clearNewAchievements() {
    _newAchievements = [];
    notifyListeners();
  }

  /// 检查心愿罐成就（创建/完成心愿后调用）
  Future<void> checkWishAchievements() async {
    if (_user == null) return;

    final wishes = await _db.getAllWishes();
    final hasCreatedWish = wishes.isNotEmpty;
    final completedWishes = wishes.where((w) => w.isCompleted).length;

    final newAchievements = AchievementChecker.checkWishAchievements(
      completedWishes: completedWishes,
      hasCreatedWish: hasCreatedWish,
      unlockedIds: _unlockedAchievements,
    );

    if (newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(newAchievements.map((a) => a.id));
      _newAchievements = newAchievements;
      final updatedUser = _user!.copyWith(achievements: _unlockedAchievements);
      await _db.updateUser(updatedUser);
      _user = updatedUser;
      notifyListeners();
    }
  }

  /// 检查预算成就（设置预算后调用）
  Future<void> checkBudgetAchievements() async {
    if (_user == null) return;

    final budgetStr = StorageService.instance.getString('monthlyBudget');
    final hasBudget = budgetStr != null && budgetStr.isNotEmpty && double.tryParse(budgetStr) != null && double.parse(budgetStr) > 0;

    final newAchievements = AchievementChecker.checkBudgetAchievements(
      hasBudget: hasBudget,
      expenseRatio: 0, // 暂不计算比例，只检查是否设置预算
      unlockedIds: _unlockedAchievements,
    );

    if (newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(newAchievements.map((a) => a.id));
      _newAchievements = newAchievements;
      final updatedUser = _user!.copyWith(achievements: _unlockedAchievements);
      await _db.updateUser(updatedUser);
      _user = updatedUser;
      notifyListeners();
    }
  }

  /// 更新用户数据（用于外部更新用户统计）
  Future<void> updateUserStats(UserModel updatedUser) async {
    await _db.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> updateUserProfile({
    String? nickname,
    String? avatar,
  }) async {
    if (_user == null) return;

    final updatedUser = _user!.copyWith(
      nickname: nickname ?? _user!.nickname,
      avatar: avatar ?? _user!.avatar,
    );
    await _db.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  /// 获取当前账本信息
  Future<BookModel?> getCurrentBook() async {
    if (_currentBookId.isEmpty) return null;
    final books = await _db.getAllBooks();
    return books.firstWhere(
      (book) => book.id == _currentBookId,
      orElse: () => books.first,
    );
  }

  /// 升级检查
  bool get shouldLevelUp => _user?.shouldLevelUp ?? false;

  /// 执行升级（支持连续升级）
  Future<void> levelUp() async {
    while (_user != null && _user!.shouldLevelUp) {
      final newLevel = _user!.level + 1;
      final newExp = _user!.exp - _user!.expForNextLevel;

      final updatedUser = _user!.copyWith(level: newLevel, exp: newExp);
      await _db.updateUser(updatedUser);
      _user = updatedUser;
    }
    notifyListeners();
  }
}
