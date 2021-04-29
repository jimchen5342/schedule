package com.flutter.schedule;

import android.app.ActivityManager;
import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.text.SimpleDateFormat;
import java.util.Calendar;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
 String TAG = "FlutterActivity";
  public static String path;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    new MethodChannel(
            flutterEngine.getDartExecutor(),
            "com.flutter.schedule/MethodChannel")
            .setMethodCallHandler(mMethodHandle);

    if(! isMyServiceRunning(AlarmService.class)) {
      Intent intent = new Intent(MainActivity.this, AlarmService.class);
      intent.setAction("com.flutter.schedule");
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        startForegroundService(intent);
      } else {
        startService(intent);
      }
    } else {
      Log.i(TAG, "Service is alive.....................");
    }
    path = Environment.getExternalStorageDirectory().toString() + File.separator + "schedule";
//    writeHistory("test", "01");
//    writeHistory("test", "02");
//    readHistory("test");
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    String boot = getIntent().getStringExtra("boot");
//    if(boot != null && boot.equals("Y")) {
//      SharedPreferences setting  = getSharedPreferences("setting", MODE_PRIVATE);
//      setting.edit().putString("setAlarm", "").putString("alarmTimes", "0").commit();
//    }
  }


  @Override
  public void onPause() {
    super.onPause();
  }
  @Override
  public void onResume() {
    super.onResume();
    AlarmService.stop();
  }
  @Override
  public void onDestroy() {
    super.onDestroy();
//    mNM.cancelAll();
  }

  private boolean isMyServiceRunning(Class<?> serviceClass) {
    ActivityManager manager = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
    for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
      if (serviceClass.getName().equals(service.service.getClassName())) {
        return true;
      }
    }
    return false;
  }


  MethodChannel.MethodCallHandler mMethodHandle = new MethodChannel.MethodCallHandler() {
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
//      Log.i(TAG, "method: " + call.method);
      AlarmService.stop();

      if(call.method.equals("setAlarm")) {
        try {
          String value = call.argument("value");
          if (value != null) {
            String s = AlarmService.setting.getString("setAlarm", "");
            Log.i(TAG, "setAlarm.value: " + value + "; storage: " + s + ", ");

            if (!s.equals(value)) {
              AlarmService.mNM.cancelAll();
              AlarmService.setting.edit()
                      .putString("setAlarm", value)
                      .putString("alarmTimes", "0")
                      .commit();
              AlarmService.setAlarm(value);
//              AlarmService.showNotification("預定：" + value);
              AlarmService.clearNotification();
            } else {

            }
          } else {
          }
          result.success("ok");
        } catch (Exception e) {
          Log.i(TAG, e.toString());
        }
      } else if(call.method.equals("clearNotifiction")) {
        AlarmService.mNM.cancelAll();
      } else if(call.method.equals("createHistoryFolder")) {
        File tDataPath = new File(path);
        if (tDataPath.exists() == false)
          createFolder(path);

        tDataPath = new File(path + File.separator + "history");
        if (tDataPath.exists() == false)
          createFolder(path + File.separator + "history");
        Log.i(TAG, path + File.separator + "history");
        result.success(path + File.separator + "history");
      } else if(call.method.equals("readHistory")) {
        String today = call.argument("today");
        String ret = readHistory(today);
        result.success(ret);
      } else if(call.method.equals("writeHistory")) {
        String today = call.argument("today");
        String value = call.argument("value");
        writeHistory(today, value);
      } else
        result.notImplemented();
    }
  };


  private void createFolder(String path) {
    File tDataPath = new File(path);
    if (tDataPath.exists() == false) {
      tDataPath.mkdir();
    }
  }

  void writeHistory(String filename, String data) {
    String _path = path + File.separator + "history" + File.separator + filename + ".txt";
    data += "\n";
    try {
        FileOutputStream out = new FileOutputStream(_path, true);
        out.write(data.getBytes());
        out.flush();
        out.close();
    } catch(FileNotFoundException e) {
      Log.i(TAG, e.getMessage());
    } catch(IOException e) {
      Log.i(TAG, e.getMessage());
    }

  }

  String readHistory(String filename) {
    String _path = path + File.separator + "history" + File.separator + filename  + ".txt";

    try {
      File file = new File(_path);
//      Log.i(TAG, "readHistory: " + _path + "; " + (file.exists() ? "exists" : "not exists"));
      if(file.exists()) {
        FileInputStream fileInputStream = new FileInputStream (file); // openFileInput(_path);
        BufferedReader br = new BufferedReader(new InputStreamReader(fileInputStream));
        String strLine, all = "";
        while ((strLine = br.readLine()) != null){
          all += (all.length() == 0 ? "" : "\n") + strLine;
        }
//        Log.i(TAG, all);
        return all;
      }
    } catch (IOException e) {
      Log.i(TAG, e.getMessage());
      e.printStackTrace();
    }
    return null;
  }
}
