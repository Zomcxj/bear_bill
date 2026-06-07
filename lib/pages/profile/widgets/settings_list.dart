import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart'; // FontSizeNotifier
import '../../../providers/app_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/database_backup_service.dart';
import '../../../services/database_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_theme.dart';

/// 设置列表
class SettingsList extends StatelessWidget {
  final VoidCallback onClearData;

  const SettingsList({super.key, required this.onClearData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        children: [
          _buildMenuItem(
            emoji: '💰',
            title: '每月预算',
            onTap: () => _showBudgetDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '🔔',
            title: '记账提醒',
            onTap: () => _showReminderDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '📤',
            title: '导出数据',
            onTap: () async {
              await DatabaseBackupService.instance.exportDatabase(context);
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '📥',
            title: '导入数据',
            onTap: () async {
              await DatabaseBackupService.instance.importDatabase(context);
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '🔤',
            title: '字号调整',
            onTap: () => _showFontSizeDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '🎨',
            title: '主题颜色',
            onTap: () => _showThemeColorDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '📖',
            title: '使用帮助',
            onTap: () => _showHelpDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: 'ℹ️',
            title: '关于',
            trailing: 'v1.1.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '小熊记账本',
                applicationVersion: 'v1.1.0',
                applicationIcon:
                    const Text('🐻', style: TextStyle(fontSize: 48)),
                children: [
                  const Text('软萌粉糖色系记账应用'),
                  const SizedBox(height: 8),
                  const Text('让记账变得有趣又可爱～'),
                ],
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '🗑️',
            title: '清空账单',
            isDanger: true,
            onTap: onClearData,
          ),
        ],
      ),
    );
  }

  /// 菜单项（对齐小程序 menu-item 样式）
  Widget _buildMenuItem({
    required String emoji,
    required String title,
    String? trailing,
    bool isDanger = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDanger ? AppTheme.primaryDark : AppTheme.textPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textHint,
                ),
              ),
            const SizedBox(width: 4),
            Text(
              '›',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textHint.withOpacity(0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppTheme.divider);
  }

  /// 显示提醒设置对话框
  Future<void> _showReminderDialog(BuildContext context) async {
    // 从本地存储读取上次设置的时间
    final storage = StorageService.instance;
    int selectedHour = int.tryParse(storage.getString('reminderHour') ?? '') ?? 20;
    int selectedMinute = int.tryParse(storage.getString('reminderMinute') ?? '') ?? 0;
    // 确保分钟值是5的倍数
    selectedMinute = (selectedMinute ~/ 5) * 5;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('⏰ 设置记账提醒'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选择每日提醒时间：'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 小时选择器
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedHour,
                      isExpanded: true,
                      items: List.generate(24, (i) => i)
                          .map((h) => DropdownMenuItem(
                                value: h,
                                child:
                                    Text('${h.toString().padLeft(2, '0')} 时'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedHour = value);
                        }
                      },
                    ),
                  ),
                  const Text(' : ', style: TextStyle(fontSize: 20)),
                  // 分钟选择器
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedMinute,
                      isExpanded: true,
                      items: List.generate(12, (i) => i * 5)
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child:
                                    Text('${m.toString().padLeft(2, '0')} 分'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedMinute = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 测试通知按钮
              TextButton.icon(
                onPressed: () async {
                  try {
                    await NotificationService.instance.showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('测试通知已发送，请查看通知栏'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('测试通知失败：$e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.notifications_active, size: 18),
                label: const Text('发送测试通知'),
              ),
              const SizedBox(height: 8),
              // 允许后台耗电引导
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.battery_saver, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        '提醒不生效？请到系统设置中允许本App后台耗电',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await NotificationService.instance.cancelDailyReminder();
                  storage.setString('reminderHour', '');
                  storage.setString('reminderMinute', '');
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已关闭记账提醒'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('关闭失败：$e')),
                    );
                  }
                }
              },
              child: const Text('关闭提醒'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await NotificationService.instance.scheduleDailyReminder(
                    hour: selectedHour,
                    minute: selectedMinute,
                  );
                  // 保存设置
                  storage.setString('reminderHour', selectedHour.toString());
                  storage.setString('reminderMinute', selectedMinute.toString());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '已设置每日 ${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')} 提醒'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('设置失败：$e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child:
                  Text('确认', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示字号调整对话框
  Future<void> _showFontSizeDialog(BuildContext context) async {
    final storage = StorageService.instance;
    String currentSize = storage.getString('fontSize') ?? '标准';

    final sizeOptions = ['小', '标准', '大'];
    final sizeMap = {
      '小': 0.7,
      '标准': 0.8,
      '大': 0.9,
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.text_fields, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text('字号调整'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: sizeOptions.map((size) {
              final isSelected = currentSize == size;
              return RadioListTile<String>(
                value: size,
                groupValue: currentSize,
                title: Row(
                  children: [
                    Text(
                      '预览文字',
                      style: TextStyle(
                        fontSize: 14 * sizeMap[size]!,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '($size)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                activeColor: AppTheme.primary,
                onChanged: (value) {
                  setState(() => currentSize = value!);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                storage.setString('fontSize', currentSize);
                Navigator.pop(context);

                // 触发全局字号刷新
                FontSizeNotifier.instance.notifyFontSizeChanged();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已设置为「$currentSize」字号'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              child:
                  Text('确认', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示使用帮助对话框
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📖 使用帮助'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('💰 如何记账？', '点击底部导航栏的「记一笔」按钮，选择分类后输入金额即可。'),
              _buildHelpItem('📊 查看统计', '在「统计」页可以看到月度收支分析、分类占比等数据。'),
              _buildHelpItem('🎯 心愿罐', '在「心愿」页创建存钱目标，每次记账时可以存入部分金额。'),
              _buildHelpItem('📒 多账本', '在「我的」-「账本管理」中可以创建多个账本，分别记录不同用途。也可点击账本数快速切换。'),
              _buildHelpItem('🔥 连续打卡', '每天记账即自动打卡，点击连续打卡可查看打卡日期。断签会重置计数。'),
              _buildHelpItem('📈 等级经验', '记账 +5 经验，每日打卡 +10 经验。经验满级自动升级，等级越高所需经验越多。'),
              _buildHelpItem('🎨 主题颜色', '在「设置」-「主题颜色」中可选择预设颜色或自定义调色盘，全应用同步切换。'),
              _buildHelpItem('💾 数据备份', '在「设置」-「导出/导入数据」可以备份数据库，换机时可导入恢复。'),
              _buildHelpItem('⏰ 记账提醒', '在「设置」-「记账提醒」中设置每日提醒时间。未记账会提醒，已记账会显示今日总结。'),
              _buildHelpItem('🔤 字号调整', '在「设置」-「字号调整」中设置字体大小，共3个选项：小、标准、大。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(content,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  /// 显示月度预算设置对话框
  Future<void> _showBudgetDialog(BuildContext context) async {
    final appProvider = context.read<AppProvider>();
    final book = await appProvider.getCurrentBook();
    final currentBudget = book?.budget ?? 0.0;
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💰 每月预算'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('设置当月消费预算上限，超支时会提醒。'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(
                hintText: '输入预算金额（元）',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
            ),
            if (currentBudget > 0) ...[
              const SizedBox(height: 8),
              Text(
                '当前预算：¥${currentBudget.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ],
          ],
        ),
        actions: [
          if (currentBudget > 0)
            TextButton(
              onPressed: () async {
                final updated = book!.copyWith(budget: 0);
                await DatabaseService.instance.updateBook(updated);
                appProvider.notifyListeners();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已清除月度预算'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              child: const Text('清除预算', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final value = double.tryParse(controller.text) ?? 0;
              if (value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效的预算金额')),
                );
                return;
              }
              final updated = book!.copyWith(budget: value);
              await DatabaseService.instance.updateBook(updated);
              appProvider.notifyListeners();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已设置月预算 ¥${value.toStringAsFixed(0)}'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: Text('确认', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  /// 显示主题颜色选择对话框
  void _showThemeColorDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎨 主题颜色'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: ThemeProvider.paletteColors.length,
                itemBuilder: (_, index) {
                  final color = ThemeProvider.paletteColors[index];
                  final isSelected =
                      themeProvider.primaryColor.value == color.value;
                  return GestureDetector(
                    onTap: () {
                      themeProvider.setPrimaryColor(color);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('主题颜色已更换'),
                          backgroundColor: AppTheme.success,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 28)
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCustomColorPicker(context, themeProvider);
                  },
                  icon: const Icon(Icons.palette, size: 18),
                  label: const Text('自定义颜色'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 自定义颜色选择器（HSV 色盘 + 明度条）
  void _showCustomColorPicker(
      BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        initialColor: themeProvider.primaryColor,
        onConfirm: (color) {
          themeProvider.setPrimaryColor(color);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('主题颜色已更换'),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}

/// HSV 颜色选择器对话框（独立 StatefulWidget 确保状态可靠）
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onConfirm;

  const _ColorPickerDialog({
    required this.initialColor,
    required this.onConfirm,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _hsv.toColor();
    return AlertDialog(
      title: const Text('🎨 自定义颜色'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 预览 + HEX
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppTheme.border),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _hsv.saturation > 0.3 && _hsv.value > 0.5
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 色相
          _buildSlider(
            label: '色相',
            value: _hsv.hue,
            max: 360,
            activeColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
            inactiveColor: HSVColor.fromAHSV(1, _hsv.hue, 0.3, 1).toColor(),
            onChanged: (v) => setState(() => _hsv = _hsv.withHue(v)),
          ),
          const SizedBox(height: 12),

          // 饱和度
          _buildSlider(
            label: '饱和',
            value: _hsv.saturation,
            max: 1,
            activeColor: _hsv.toColor(),
            inactiveColor: HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
            onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
          ),
          const SizedBox(height: 12),

          // 明度
          _buildSlider(
            label: '明度',
            value: _hsv.value,
            max: 1,
            min: 0.2,
            activeColor: _hsv.toColor(),
            inactiveColor: HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 0.2).toColor(),
            onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onConfirm(selectedColor);
            Navigator.pop(context);
          },
          child: Text('确认', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    double min = 0,
    required Color activeColor,
    required Color inactiveColor,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              thumbColor: activeColor,
              inactiveTrackColor: inactiveColor,
              overlayColor: Colors.transparent,
              trackHeight: 10,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              min: min,
              max: max,
              value: value.clamp(min, max),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
