import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart'; // FontSizeNotifier
import '../../../providers/app_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/database_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';

/// 显示提醒设置对话框（滚动选择器）
Future<void> showReminderDialog(BuildContext context) async {
  final storage = StorageService.instance;
  int selectedHour = int.tryParse(storage.getString('reminderHour') ?? '') ?? 20;
  int selectedMinute = int.tryParse(storage.getString('reminderMinute') ?? '') ?? 0;
  selectedMinute = (selectedMinute ~/ 5) * 5;

  final hourController = FixedExtentScrollController(initialItem: selectedHour);
  final minuteController = FixedExtentScrollController(initialItem: selectedMinute ~/ 5);

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      height: 360,
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(DS.radiusMd)),
      ),
      child: Column(
        children: [
          // 顶部操作栏
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: DS.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    try {
                      await NotificationService.instance.cancelDailyReminder();
                      storage.setString('reminderHour', '');
                      storage.setString('reminderMinute', '');
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已关闭记账提醒'), backgroundColor: DS.secondary),
                        );
                      }
                    } catch (_) {}
                  },
                  child: Text('关闭提醒', style: TextStyle(color: DS.error)),
                ),
                Text('设置提醒时间', style: DS.headlineSm),
                TextButton(
                  onPressed: () async {
                    try {
                      await NotificationService.instance.scheduleDailyReminder(
                        hour: selectedHour,
                        minute: selectedMinute,
                      );
                      storage.setString('reminderHour', selectedHour.toString());
                      storage.setString('reminderMinute', selectedMinute.toString());
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已设置每日 ${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')} 提醒'),
                            backgroundColor: DS.secondary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('设置失败：$e'), backgroundColor: DS.error),
                        );
                      }
                    }
                  },
                  child: Text('确定'),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // 滚动选择器
          Expanded(
            child: Row(
              children: [
                // 小时
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: hourController,
                    itemExtent: 44,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => selectedHour = i,
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 23) return null;
                        return Center(
                          child: Text(
                            '${index.toString().padLeft(2, '0')} 时',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                // 分钟
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: minuteController,
                    itemExtent: 44,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => selectedMinute = i * 5,
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 11) return null;
                        return Center(
                          child: Text(
                            '${(index * 5).toString().padLeft(2, '0')} 分',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 提示
          Padding(
            padding: EdgeInsets.all(DS.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: DS.outline),
                SizedBox(width: DS.xs),
                Text('提醒不生效？请允许本App后台耗电', style: DS.labelSm.copyWith(color: DS.outline)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// 显示字号调整对话框
Future<void> showFontSizeDialog(BuildContext context) async {
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
            Icon(Icons.text_fields, color: DS.primary),
            SizedBox(width: 8),
            Text('字号调整'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sizeOptions.map((size) {
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
                  SizedBox(width: 12),
                  Text(
                    '($size)',
                    style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                  ),
                ],
              ),
              activeColor: DS.primary,
              onChanged: (value) {
                setState(() => currentSize = value!);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
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
                Text('确认', style: TextStyle(color: DS.primary)),
          ),
        ],
      ),
    ),
  );
}

/// 帮助项组件
Widget _buildHelpItem(IconData icon, String title, String content) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: DS.primary),
            SizedBox(width: 6),
            Text(title,
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        SizedBox(height: 4),
        Text(content,
            style:
                DS.labelSm.copyWith(color: DS.onSurfaceVariant)),
      ],
    ),
  );
}

/// 显示使用帮助对话框
void showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, color: DS.primary, size: 24),
          SizedBox(width: 8),
          Text('使用帮助'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(Icons.edit, '手动记账', '点击首页右下角「记一笔」按钮，选择分类后输入金额即可。支持心情标签、定位、图片附件。'),
            _buildHelpItem(Icons.auto_awesome, 'AI 智能记账', '点击首页话筒按钮按住说话，或进入 AI 记账页面输入自然语言，如"午餐花了25"、"打车去公司"，AI 自动识别分类和金额。'),
            _buildHelpItem(Icons.chat, 'AI 对话查询', '在 AI 记账页面可以用自然语言查询账单，如"这个月餐饮花了多少"、"上个月交通支出"、"开心时候的消费"。'),
            _buildHelpItem(Icons.mic, '语音输入', '首页话筒按钮支持按住说话，松开自动识别并跳转 AI 记账。上滑可取消录音。'),
            _buildHelpItem(Icons.map, '消费地图', '在「设置」-「消费地图」中查看所有带定位的消费记录在地图上的分布，了解消费足迹。'),
            _buildHelpItem(Icons.leaderboard, '统计报表', '在「统计」页可切换月度/年度报表，查看收支趋势、分类占比、AI 洞察分析。'),
            _buildHelpItem(Icons.track_changes, '心愿储蓄罐', '在「心愿」页创建存钱心愿，设置心愿金额和截止日期，每次可存入部分金额。'),
            _buildHelpItem(Icons.book, '多账本', '在首页点击账本名称可切换账本，「我的」-「账本管理」中可创建多个账本分别记录。'),
            _buildHelpItem(Icons.local_fire_department, '连续打卡', '每天记账即自动打卡，断签会重置计数。等级经验：记账 +5，打卡 +10。'),
            _buildHelpItem(Icons.backup, '数据备份', '在「设置」-「导出/导入数据」可以备份数据库文件，换机时可导入恢复。'),
            _buildHelpItem(Icons.alarm, '记账提醒', '在「设置」-「记账提醒」中设置每日提醒时间，未记账时会推送通知。'),
            _buildHelpItem(Icons.smart_toy, '自动记账', '在「设置」-「自动记账」中开启微信/支付宝通知监听，收到支付通知自动记账。'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('知道了'),
        ),
      ],
    ),
  );
}

/// 显示月度预算设置对话框
Future<void> showBudgetDialog(BuildContext context) async {
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
      title: Row(
        children: [
          Icon(Icons.savings, color: DS.primary, size: 24),
          SizedBox(width: 8),
          Text('每月预算'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设置当月消费预算上限，超支时会提醒。'),
          SizedBox(height: 16),
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
            SizedBox(height: 8),
            Text(
              '当前预算：¥${currentBudget.toStringAsFixed(0)}',
              style: DS.labelSm.copyWith(color: DS.outline),
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
              appProvider.refreshCurrentBook();
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
            child: Text('清除预算', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
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
            appProvider.refreshCurrentBook();
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
          child: Text('确认', style: TextStyle(color: DS.primary)),
        ),
      ],
    ),
  );
}

/// 显示主题颜色选择对话框
void showThemeColorDialog(BuildContext context, ThemeProvider themeProvider) {
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.palette, color: DS.primary, size: 24),
          SizedBox(width: 8),
          Text('主题颜色'),
        ],
      ),
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
                        ? Icon(Icons.check,
                            color: Colors.white, size: 28)
                        : null,
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            // 深色模式开关
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.dark_mode, size: 20, color: DS.onSurface),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '深色模式',
                      style: DS.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: DS.onSurface,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) {
                        themeProvider.toggleDarkMode();
                        setDialogState(() {});
                      },
                      activeColor: DS.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  showCustomColorPicker(context, themeProvider);
                },
                icon: Icon(Icons.palette, size: 18),
                label: Text('自定义颜色'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DS.primary,
                  side: BorderSide(color: DS.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DS.radiusSm),
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
          child: Text('关闭'),
        ),
      ],
    ),
  ),
  );
}

/// 自定义颜色选择器（HSV 色盘 + 明度条）
void showCustomColorPicker(
    BuildContext context, ThemeProvider themeProvider) {
  showDialog(
    context: context,
    builder: (ctx) => ColorPickerDialog(
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

/// HSV 颜色选择器对话框（独立 StatefulWidget 确保状态可靠）
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onConfirm;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onConfirm,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
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
      title: Row(
        children: [
          Icon(Icons.palette, color: DS.primary, size: 24),
          SizedBox(width: 8),
          Text('自定义颜色'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 预览 + HEX
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius: BorderRadius.circular(DS.radiusSm),
              border: Border.all(color: DS.outlineVariant),
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
          SizedBox(height: 16),

          // 色相
          _buildSlider(
            label: '色相',
            value: _hsv.hue,
            max: 360,
            activeColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
            inactiveColor: HSVColor.fromAHSV(1, _hsv.hue, 0.3, 1).toColor(),
            onChanged: (v) => setState(() => _hsv = _hsv.withHue(v)),
          ),
          SizedBox(height: 12),

          // 饱和度
          _buildSlider(
            label: '饱和',
            value: _hsv.saturation,
            max: 1,
            activeColor: _hsv.toColor(),
            inactiveColor: HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
            onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
          ),
          SizedBox(height: 12),

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
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onConfirm(selectedColor);
            Navigator.pop(context);
          },
          child: Text('确认', style: TextStyle(color: DS.primary)),
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
          child: Text(label, style: TextStyle(fontSize: 13)),
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
