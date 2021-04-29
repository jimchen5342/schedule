package com.flutter.schedule;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

/* 無效 */
public class StartService extends Service {
	@Override
	public void onCreate() {
		super.onCreate();
		Log.i("Flutter", "StartService.onCreate...................");
		startForeground(this);
		stopSelf();
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		stopForeground(true);
		Log.i("Flutter", "StartService.onDestroy...................");
	}

	public static void startForeground(Service context) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			NotificationChannel channel = new NotificationChannel(AlarmService.CHANNEL, AlarmService.CHANNEL,
							NotificationManager.IMPORTANCE_LOW);
			channel.enableVibration(false);
			channel.enableLights(false);

//			NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
//			manager.createNotificationChannel(channel);
			AlarmService.mNM.createNotificationChannel(channel);

			Notification notification = new Notification.Builder(context.getApplicationContext(), AlarmService.CHANNEL).build();
			context.startForeground( AlarmService.startForegroundId, notification);
		}
	}

	@Override
	public IBinder onBind(Intent intent) {
		return null;
	}
}