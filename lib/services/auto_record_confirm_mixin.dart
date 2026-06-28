import 'dart:async';

import 'package:flutter/material.dart';

import '../pages/add_record/add_record_page.dart';
import '../theme/app_design_system.dart';
import 'auto_record_service.dart';

/// 自动记账确认 Mixin — 检测到支付后跳转记账页面预填数据
mixin AutoRecordConfirmMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  StreamSubscription<AutoRecordCandidate>? _autoRecordSub;
  bool _navigating = false; // 防止双重触发

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoRecordSub = AutoRecordService.instance.onCandidateDetected.listen(
      (candidate) {
        if (mounted && !_navigating) {
          _navigateToAddRecord(candidate);
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = AutoRecordService.instance.pendingCandidate;
      if (pending != null && mounted && !_navigating) {
        _navigateToAddRecord(pending);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRecordSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // app 回到前台时，检查暂存的支付数据
    if (state == AppLifecycleState.resumed) {
      // 先检查原生端暂存的数据
      AutoRecordService.instance.checkPendingPayment().then((_) {
        // 然后检查是否有待确认的候选
        final pending = AutoRecordService.instance.pendingCandidate;
        if (pending != null && mounted && !_navigating) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_navigating) {
              _navigateToAddRecord(pending);
            }
          });
        }
      });
    }
  }

  void _navigateToAddRecord(AutoRecordCandidate candidate) {
    if (_navigating) return;
    _navigating = true;

    final record = candidate.record;
    final sourceLabel = candidate.source == 'wechat'
        ? '微信'
        : candidate.source == 'alipay'
            ? '支付宝'
            : '银行';

    // 跳转到记账页面，预填检测到的数据
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordPage(
          prefillRecord: record,
        ),
      ),
    ).then((_) {
      // 返回后清除待确认状态，重置防重入标志
      AutoRecordService.instance.dismissRecord();
      _navigating = false;
    });

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '检测到$sourceLabel支付 ¥${record.amount.toStringAsFixed(2)}，请补充分类和备注'),
        backgroundColor: DS.inverseSurface,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
