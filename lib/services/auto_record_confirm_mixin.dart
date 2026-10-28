import 'dart:async';

import 'package:flutter/material.dart';

import '../pages/add_record/add_record_page.dart';
import '../theme/app_design_system.dart';
import 'auto_record_service.dart';

/// Auto-record confirm mixin — after a payment is detected, navigate to the add-record page with prefilled data
mixin AutoRecordConfirmMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  StreamSubscription<AutoRecordCandidate>? _autoRecordSub;
  bool _navigating = false; // prevent double triggering

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
    // When the app returns to the foreground, check the cached payment data
    if (state == AppLifecycleState.resumed) {
      // First check the data cached on the native side
      AutoRecordService.instance.checkPendingPayment().then((_) {
        // Then check whether there is a candidate pending confirmation
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

    // Navigate to the add-record page and prefill the detected data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordPage(
          prefillRecord: record,
        ),
      ),
    ).then((_) {
      // On return, clear the pending state and reset the re-entrancy flag
      AutoRecordService.instance.dismissRecord();
      _navigating = false;
    });

    // Show a prompt
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
