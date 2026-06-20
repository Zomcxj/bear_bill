import 'package:flutter/material.dart';

import '../../../services/auto_record_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';

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
    final enabled =
        await AutoRecordService.instance.isNotificationListenerEnabled();
    if (mounted) {
      setState(() => _listenerEnabled = enabled);
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

    if (value) {
      AutoRecordService.instance.startPolling();
    } else {
      AutoRecordService.instance.stopPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            '监听微信/支付宝支付通知，自动识别并记录账单',
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
                  color: _listenerEnabled ? AppTheme.success : DS.primaryContainer,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _listenerEnabled ? '通知监听权限已开启' : '需要开启通知读取权限',
                    style: TextStyle(
                      fontSize: 13,
                      color: _listenerEnabled ? AppTheme.success : DS.primaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!_listenerEnabled)
                  TextButton(
                    onPressed: () async {
                      await AutoRecordService.instance
                          .openNotificationListenerSettings();
                      // 返回后由 didChangeAppLifecycleState 重新检查
                    },
                    child: Text('去开启'),
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
                  '• 微信支付\n• 支付宝',
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
