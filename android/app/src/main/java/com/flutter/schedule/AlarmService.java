package com.flutter.schedule;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.AssetFileDescriptor;
import android.graphics.Color;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Calendar;

import androidx.core.app.NotificationCompat;

import static android.app.Notification.VISIBILITY_SECRET;

public class AlarmService extends Service {
	public static String TAG = "FlutterService", CHANNEL = "com.flutter.schedule";
	public static SharedPreferences setting;
	public static NotificationManager mNM;
	static SimpleDateFormat sdfDateTime = new SimpleDateFormat("yyyy-MM-dd HH:mm");
	static AlarmService alarmService;
	public static int startForegroundId = 1;
	static MediaPlayer mediaPlayer;

	@Override
	public void onCreate() {
		super.onCreate();
		alarmService = this;

		setting = getSharedPreferences("setting", MODE_PRIVATE);

		mNM = (NotificationManager)getSystemService(NOTIFICATION_SERVICE);
		startForeground2();
		Calendar calendar = Calendar.getInstance();
	}
//	private MediaPlayer.OnCompletionListener onCompletionListener = new MediaPlayer.OnCompletionListener() {
//		@Override
//		public void onCompletion(MediaPlayer mp) {
//			// TODO Auto-generated method stub
////			mediaPlayer.release();
////			mediaPlayer = null;
//		}
//	};

	static void play(Context context){
		try {
			AssetFileDescriptor fd = null;
			mediaPlayer = new MediaPlayer();
			fd = context.getApplicationContext().getAssets().openFd("clock.mp3");
			mediaPlayer.setDataSource(fd.getFileDescriptor(), fd.getStartOffset(), fd.getLength());

			mediaPlayer.prepare();
			mediaPlayer.start();
		} catch (IllegalArgumentException e) {
			e.printStackTrace();
			Log.i(TAG, "MP3-1: " + e.getMessage());
		} catch (SecurityException e) {
			e.printStackTrace();
			Log.i(TAG, "MP3-2: " + e.getMessage());
		} catch (IllegalStateException e) {
			e.printStackTrace();
			Log.i(TAG, "MP3-3: " + e.getMessage());
		} catch (IOException e) {
			e.printStackTrace();
			Log.i(TAG, "MP3-4: " + e.getMessage());
		}
	}
	static void stop(){
		if(mediaPlayer != null) {
			mediaPlayer.stop();
			mediaPlayer = null;
		}
		Log.i(TAG, "MP3 stop...........");
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		// startForeground2();
		if(intent != null) {
			Log.i(TAG, "onStart.action: " + intent.getAction() + " ====================>");
			String action = intent.getAction();
			if(action != null && action.equals("com.flutter.schedule.alarm.receiver")) {
				show(this);
			}
		}
		return START_STICKY;
	}

	public void startForeground2() {
		// showNotification("");
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			if(1 == 0) { // ??????
				// 		StartService.startForeground(this);
				// 		Intent intent = new Intent(this, StartService.class);
				// 		startService(intent);
			}  else {
				String sChannel = CHANNEL + ".start";
				NotificationChannel channel = new NotificationChannel(sChannel, sChannel, NotificationManager.IMPORTANCE_NONE);
				channel.enableVibration(false);
				channel.enableLights(false);
				channel.setLightColor(Color.YELLOW);
				channel.enableLights(false);//?????????

				NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
				manager.createNotificationChannel(channel);

				Notification.Builder build = new Notification.Builder(getApplicationContext(), sChannel);
				Notification notification = build.build();

				startForeground(startForegroundId + 1, notification);
			}
		}
	}

	static void show(Context context){
		String s = setting.getString("setAlarm", "");
		int alarmTimes = Integer.parseInt(setting.getString("alarmTimes", "0"));
		Calendar calendar = Calendar.getInstance();
		if(calendar.get(Calendar.HOUR_OF_DAY) >= 20){
			play(context);
		}
		calendar.add(Calendar.MINUTE, alarmTimes < 3 ? 5 : 3);

		alarmTimes++;
		setting.edit()
		//.putString("setAlarm", s)
		.putString("alarmTimes", Integer.toString(alarmTimes))
		.commit();

		Log.i(TAG, "show: " + s + ", ??? " + Integer.toString(alarmTimes) + " ???..................." );
		setAlarm(calendar);
		showNotification(s + "; ??? " + Integer.toString(alarmTimes) + " ?????????!!");
	}


	static void setAlarm(String date) { //
		Calendar calendar = Calendar.getInstance();
		try {
			calendar.setTime(sdfDateTime.parse(date));
			setAlarm(calendar);
		} catch (Exception e) {
			Log.w(TAG, e.toString());
		}
	}

	static void setAlarm(Calendar calendar){ //
		final AlarmManager am = (AlarmManager) alarmService.getSystemService(ALARM_SERVICE);
		// test start-------------------------------
		if(1 == 0) {
			calendar = Calendar.getInstance();
			calendar.add(Calendar.SECOND, 60);
//    String name = calendar.getTimeZone().getDisplayName();
//    int mMonth = calendar.get(Calendar.MONTH);
//    int mDay = calendar.get(Calendar.DATE);
//    int mHour = calendar.get(Calendar.HOUR_OF_DAY);
//    int mMinute = calendar.get(Calendar.MINUTE) + 1;
//    calendar.set(2020, mMonth, mDay, mHour, mMinute,0);
		}
		// test end-------------------------------
		// Log.i(TAG, "setAlarm: " + sdfDateTime.format(calendar.getTime()));
		Intent i = new Intent("com.flutter.schedule.alarm");
		i.setClass(alarmService, AlarmReceiver.class);
		i.putExtra("time", sdfDateTime.format(calendar.getTime()));

		PendingIntent pi = PendingIntent.getBroadcast(alarmService, 1, i,PendingIntent.FLAG_UPDATE_CURRENT);
		am.set(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(), pi);       //????????????

		Log.i(TAG, "setAlarm: " + sdfDateTime.format(calendar.getTime()));
		//    am.cancel(pi);    //??????????????????????????????
	}

	public static void showNotification(String memo) {
		mNM.cancelAll();
		Intent intent = new Intent(alarmService, MainActivity.class);
		intent.setAction("com.flutter.schedule.notification");
		intent.putExtra("notification", "Y");
		intent.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT); //  | Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK
		PendingIntent pendingIntent = PendingIntent.getActivity(alarmService, 0, intent, 0);

		NotificationCompat.Builder builder = new NotificationCompat.Builder(alarmService, CHANNEL);
		boolean level =  memo.length() == 0 ? false : true; // memo.indexOf("?????????") > -1 ||
		// level = true;
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			// 	alarmService.stopForeground(true);
			// 	mNM.cancel(startForegroundId);
			int importance = level == true ? NotificationManager.IMPORTANCE_HIGH : NotificationManager.IMPORTANCE_NONE;
			// 	importance = NotificationManager.IMPORTANCE_NONE;
			NotificationChannel channel = new NotificationChannel(CHANNEL, CHANNEL, importance);
			channel.enableLights(level);//?????????
			channel.setLightColor(Color.YELLOW);//????????????????????????
			channel.enableVibration(level);//??????????????????
			channel.setVibrationPattern(new long[]{100, 200, 300, 400, 500, 400, 300, 200, 400}); //??????????????????
			channel.setLockscreenVisibility(VISIBILITY_SECRET);//??????????????????

			// 	channel.getAudioAttributes();//???????????????????????????????????????
			// 	channel.getGroup(); //?????????????????????
			// 	  channel.canBypassDnd(); //??????????????????????????????
			// 	channel.canShowBadge(); //??????launcher???????????????
			// 	channel.setBypassDnd(true); //???????????????  ??????????????????
			// 	channel.shouldShowLights(); //??????????????????
			mNM.createNotificationChannel(channel);
		// 	builder = new NotificationCompat.Builder(context, CHANNEL);
    }
    else {
			builder
						.setLights(Color.YELLOW, 2000, 2000)
						.setVibrate(new long[]{100, 200, 300, 400, 500, 400, 300, 200, 400})
						.setPriority(level == true ? Notification.PRIORITY_HIGH :  Notification.PRIORITY_LOW); // ??????
    }

		builder.setDefaults(Notification.DEFAULT_ALL)
			.setContentTitle("Schedule")
			.setContentText(memo)
			.setSmallIcon(R.mipmap.ic_launcher)
			.setContentIntent(pendingIntent)
		// 				.setSound(Settings.System.DEFAULT_NOTIFICATION_URI)
			.setAutoCancel(true);
		Notification notify = builder.build();
		// if(level == true) notify.flags = Notification.FLAG_SHOW_LIGHTS;
		// if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
		// 	alarmService.startForeground(startForegroundId, notify);
		// else
			mNM.notify(startForegroundId, notify);
	}

	public static void clearNotification() {
		mNM.cancel(startForegroundId);
		// mNM.cancelAll();
	}
	@Override
	public void onDestroy(){
		super.onDestroy();
		stopForeground(true);
	}

	@Override
	public IBinder onBind(Intent intent) {
		return null;
	}
}
