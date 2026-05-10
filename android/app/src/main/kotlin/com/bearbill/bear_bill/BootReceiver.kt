package com.bearbill.bear_bill

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            // 从 SharedPreferences 读取保存的提醒时间并重新调度
            val prefs = context.getSharedPreferences("alarm_prefs", Context.MODE_PRIVATE)
            val hour = prefs.getInt("reminder_hour", -1)
            val minute = prefs.getInt("reminder_minute", -1)

            if (hour >= 0 && minute >= 0) {
                AlarmScheduler.scheduleDaily(context, hour, minute)
            }
        }
    }
}
