import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/auto_record_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// 自动记账设置对话框
Future<void> showAutoRecordDialog(BuildContext context) async {
  final enabled = await AutoRecordService.instance.isAutoRecordEnabled();

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (context) => _AutoRecordDialogContent(enabled: enabled),
  );
}

class _AutoRecordDialogContent extends StatefulWidget {
  final bool enabled;

  const _AutoRecordDialogContent({required this.enabled});

  @override
  State<_AutoRecordDialogContent> createState() =>
      _AutoRecordDialogContentState();
}

class _AutoRecordDialogContentState extends State<_AutoRecordDialogContent>
    with WidgetsBindingObserver {
  late bool _enabled;
  bool _listenerEnabled = false;
  bool _listenerRunning = false;
  bool _accessibilityEnabled = false;
  String _lastNotificationInfo = '';

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    WidgetsBinding.instance.addObserver(this);
    _checkListenerStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从系统设置页返回时重新检查权限
    if (state == AppLifecycleState.resumed) {
      _checkListenerStatus();
    }
  }

  Future<void> _checkListenerStatus() async {
    final listenerEnabled =
        await AutoRecordService.instance.isNotificationListenerEnabled();
    final listenerRunning =
        await AutoRecordService.instance.isNotificationListenerRunning();
    final accessibilityEnabled =
        await AutoRecordService.instance.isAccessibilityEnabled();

    // 读取最后收到的通知信息
    String lastInfo = '';
    try {
      final result = await const MethodChannel('bear_bill/auto_record')
          .invokeMethod<Map>('getLastNotification');
      if (result != null) {
        final pkg = result['package'] ?? '';
        final title = result['title'] ?? '';
        final text = result['text'] ?? '';
        final time = result['time'] ?? 0;
        if (pkg.isNotEmpty) {
          final dt = DateTime.fromMillisecondsSinceEpoch(time);
          lastInfo =
              '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} [$pkg]\n$title: $text';
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _listenerEnabled = listenerEnabled;
        _listenerRunning = listenerRunning;
        _accessibilityEnabled = accessibilityEnabled;
        _lastNotificationInfo = lastInfo;
      });
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    if (value && !_listenerEnabled) {
      // 需要先开启通知监听权限
      await AutoRecordService.instance.openNotificationListenerSettings();
      // 不在这里检查，等用户从设置页返回后由 didChangeAppLifecycleState 触发
      return;
    }

    setState(() => _enabled = value);
    await AutoRecordService.instance.setAutoRecordEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.smart_toy, color: DS.primary, size: 24),
          SizedBox(width: 8),
          Text('自动记账'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '监听支付宝/银行卡通知，识别后跳转记账页确认',
            style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
          ),
          SizedBox(height: 16),

          // 通知监听权限状态
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _listenerEnabled
                  ? AppTheme.success.withOpacity(0.1)
                  : DS.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DS.radiusSm),
              border: Border.all(
                color: _listenerEnabled
                    ? AppTheme.success.withOpacity(0.3)
                    : DS.primaryContainer.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _listenerEnabled ? Icons.check_circle : Icons.warning,
                  size: 20,
                  color:
                      _listenerEnabled ? AppTheme.success : DS.primaryContainer,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _listenerEnabled ? '通知监听权限已开启' : '需要开启通知读取权限',
                        style: TextStyle(
                          fontSize: 13,
                          color: _listenerEnabled
                              ? AppTheme.success
                              : DS.primaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_listenerEnabled)
                        Text(
                          _listenerRunning ? '服务已被系统绑定' : '等待系统绑定，以下方最近通知为准',
                          style: TextStyle(
                            fontSize: 11,
                            color: _listenerRunning
                                ? AppTheme.success
                                : AppTheme.warning,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_listenerEnabled)
                  TextButton(
                    onPressed: () async {
                      await AutoRecordService.instance
                          .openNotificationListenerSettings();
                    },
                    child: Text('去开启'),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12),

          // 无障碍服务状态
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accessibilityEnabled
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DS.radiusSm),
              border: Border.all(
                color: _accessibilityEnabled
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.warning.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _accessibilityEnabled
                      ? Icons.check_circle
                      : Icons.accessibility_new,
                  size: 20,
                  color: _accessibilityEnabled
                      ? AppTheme.success
                      : AppTheme.warning,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _accessibilityEnabled ? '无障碍辅助已开启' : '无障碍辅助未开启',
                        style: TextStyle(
                          fontSize: 13,
                          color: _accessibilityEnabled
                              ? AppTheme.success
                              : AppTheme.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '实验辅助，通知监听才是主路径',
                        style: TextStyle(
                          fontSize: 11,
                          color: DS.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_accessibilityEnabled)
                  TextButton(
                    onPressed: () async {
                      await AutoRecordService.instance
                          .openAccessibilitySettings();
                    },
                    child: Text('去开启'),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12),

          // 调试信息：最后收到的通知
          if (_lastNotificationInfo.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DS.background,
                borderRadius: BorderRadius.circular(DS.radiusXs),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最后收到的通知',
                    style: DS.labelSm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DS.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _lastNotificationInfo,
                    style: DS.labelSm.copyWith(color: DS.outline),
                  ),
                ],
              ),
            ),
          SizedBox(height: 16),

          // 自动记账开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '启用自动记账',
                style: DS.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: DS.onSurface,
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: _toggleEnabled,
                activeColor: DS.primary,
              ),
            ],
          ),
          SizedBox(height: 12),

          // 提示
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DS.background,
              borderRadius: BorderRadius.circular(DS.radiusXs),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '支持的应用',
                  style: DS.labelSm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DS.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• 支付宝（交易提醒弹窗）\n• 主流银行 App（通知栏消息）',
                  style: DS.labelSm.copyWith(color: DS.outline),
                ),
                SizedBox(height: 8),
                Text(
                  '识别的内容',
                  style: DS.labelSm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DS.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• 支付成功通知\n• 转账/红包通知',
                  style: DS.labelSm.copyWith(color: DS.outline),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),

          // 测试按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context); // 关闭设置弹窗
                await AutoRecordService.instance.simulatePayment(
                  title: '支付宝',
                  text: '你有一笔25.00元的支出，点击查看详情',
                  source: 'alipay',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已模拟支付宝支付，请查看是否跳转记账页面')),
                  );
                }
              },
              icon: Icon(Icons.bug_report, size: 16),
              label: Text('发送测试通知'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('关闭'),
        ),
      ],
    );
  }
}
