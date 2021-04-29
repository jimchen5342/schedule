package com.flutter.schedule;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class AlarmReceiver extends BroadcastReceiver {
	String TAG = "Flutter.AlarmReceiver";
	@Override
	public void onReceive(Context context, Intent intent) {
		if (intent.getAction().equals("com.flutter.schedule.alarm")) {
			Intent i = new Intent("com.flutter.schedule.alarm.receiver");
			i.setClass(context, AlarmService.class);
			context.startService(i);
      Log.i(TAG, "AlarmReceiver...................");
		}
	}
}