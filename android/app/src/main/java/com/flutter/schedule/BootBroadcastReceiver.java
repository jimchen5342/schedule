package com.flutter.schedule;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import static android.content.Context.MODE_PRIVATE;

public class BootBroadcastReceiver extends BroadcastReceiver {
	static final String ACTION = "android.intent.action.BOOT_COMPLETED";

	public void onReceive(Context context, Intent intent) {
		Log.i("FlutterActivity", "BootBroadcastReceiver");
		if (intent.getAction().equals(ACTION)) {
			SharedPreferences setting  = context.getSharedPreferences("setting", MODE_PRIVATE);
			setting.edit().putString("setAlarm", "").putString("alarmTimes", "0").commit();

			Intent i = new Intent(context, MainActivity.class);
//			i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			i.setAction("com.flutter.schedule.boot");
			i.putExtra("boot", "Y");
			context.startActivity(i);
		}
	}
}
