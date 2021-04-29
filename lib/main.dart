import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:schedule/setup.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schedule',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Schedule'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final methodChannel = const MethodChannel('com.flutter.schedule/MethodChannel');
  DateTime today =  DateTime.now();
  int year, month, hh = 21, mm = 30, mode = 0;
  String fmtDate = "yyyyMMdd", fmtTime = "HH:mm", fmtDateTime = "yyyy-MM-dd HH:mm";
  final LocalStorage storage = new LocalStorage('storage');
  Map<String, dynamic> history, schedule;

  @override
  void initState() {
    super.initState();
    year = today.year;
    month = today.month;
    _requestPermissions().then((permission){
      if(permission == true){
        storage.ready.then((b) async {
          var path = await methodChannel.invokeMethod('createHistoryFolder');
          print("Permissions: $path");
          // storage.clear();
          history = storage.getItem('history') ?? {};
          schedule = storage.getItem('schedule') ?? {};
          mode = storage.getItem('mode') ?? 0; // 上班日 15:00, 21:30
          hh = storage.getItem('hour') ?? 21;
          mm = storage.getItem('minute') ?? 30;
          var s = DateFormat(fmtDate).format(today);
          var dt = DateTime(today.year, today.month, today.day);
          if(history.containsKey(s)) {
            dt = dt.add(Duration(days: 1));
          }
          setAlarm(dt);
          var _today = DateFormat(fmtDate).format(today);
          List<String> _schedule = List();
          schedule.forEach((key, value){
            if(key.compareTo(_today) == -1) {
              _schedule.add(key);
            }
          });
          _schedule.forEach((key){
            schedule.remove(key);
          });
          new Timer(new Duration(seconds: 1), (){
            setState(() {});
          });
          
        });
      }
    });
  }
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }
  @override
  void reassemble() async { 
    super.reassemble();
    // history = {}; 
    // schedule = {};
    // storage.clear();    
    // print("reassemble.................3");

    DateTime dt = DateTime.now();//
    dt = dt.add(Duration(minutes: -9));
    TimeOfDay t = TimeOfDay(hour: dt.hour, minute: dt.minute);
    setAlarm(dt, time: t); 
  }
  @override
  void dispose() {
    super.dispose();
  }
  void didChangeAppLifecycleState(AppLifecycleState state) { // App 生命週期
    switch (state) {
      case AppLifecycleState.resumed:
        today = DateTime.now();
        setState(() {});
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
        break;
      default:
        break;
    }
  }

  Future<bool> _requestPermissions() async {
    Map<PermissionGroup, PermissionStatus> permissions = 
      await PermissionHandler().requestPermissions([
        PermissionGroup.storage,
        PermissionGroup.notification
      ]);
    bool b = true;
    for (var key in permissions.keys) {
      if (permissions[key] != PermissionStatus.granted) {
        b = false;
        break;
      }
    }
    return b;
  }

  void setAlarm(DateTime day, {TimeOfDay time, String next}) async {
    var s = DateFormat(fmtDate).format(day);
    int hour = mode == 1 ? hh : 15,
      minute = mode == 1 ? mm : 0;

    if(time != null) {
      hour = time.hour;
      minute = time.minute;
    } else if(schedule.containsKey(s)) {
      var arr = schedule[s].split(":");
      if(arr.length == 2) {
        hour = int.parse(arr[0]);
        minute = int.parse(arr[1]);
      }
    } else if(mode == 0 && (day.weekday > 5)) {
      hour = 14;
    }

    var dt = DateTime(day.year, day.month, day.day, hour, minute);
    var s4 = DateFormat(fmtDate).format(dt);
    if(!schedule.containsKey(s4)) {
      schedule[s4] = DateFormat(fmtTime).format(dt); // 不存 storage
    }
    var result = await methodChannel.invokeMethod('setAlarm', {
      "value": DateFormat(fmtDateTime).format(dt),
      "next": next
    });
    // print("setAlarm: $schedule");
  }
  @override
  Widget build(BuildContext context) {
    List<Widget> child;
    if(schedule == null) {
      child = [
        Expanded(flex: 1, child: Text("")),
        Text("Schedle",
          textAlign: TextAlign.center,
          style: new TextStyle(
            fontSize: 40.0,
            color: Colors.blue
          )
        ),
        Expanded(flex: 1, child: Text("")),
        Text("version 2020-03-23 11:40",
          textAlign: TextAlign.right,
          style: new TextStyle(
            fontSize: 20.0,
            color: Colors.red[300]
          )
        )
      ];
    } else {
       child = [
        header(),
        week(),
        Expanded(flex: 1, child: calendar()),
        // Row(children: <Widget>[
        //   bntOK()
        // ])
        bntOK()
      ];
    }
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: Container(
        padding: EdgeInsets.only(top: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: child,
        ),
      ),
    );
  }

  Widget header(){
    return Container(child: 
      Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 20, 
              color:  Colors.white
            ),
            onPressed: () { 
              month--;
              if(month <= 0){
                month = 12;
                year--;
              }
              today = DateTime.now();
              setState(() {});
            },
          ),
          Expanded( 
            flex: 1,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                onTap: () {
                  setup();
                }, 
                child: Text( "$year 年 $month 月",
                  style: new TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 20, 
              color:  Colors.white
            ),
            onPressed: () { 
              month++;
              if(month > 12){
                month = 1;
                year++;
              }
              today = DateTime.now();
              setState(() {});
            },
          ),
        ]
      ),
      decoration: ShapeDecoration(
        color: Colors.blue,
        shape: RoundedRectangleBorder(
          // borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
  Widget week(){
    var weeks = ["一", "二", "三", "四", "五", "六", "日"];
    List<Widget> rows = [];
    for(var i = 0; i < weeks.length; i++) {
      rows.add(
        Expanded( 
          flex: 1,
          child: Align(
            alignment: Alignment.center,
            child: Text("星期"+weeks[i],
              style: new TextStyle(
                // fontSize: 18.0,
                color: i >= 5 ? Colors.orange[900] : Colors.black
              ),
            )
          )
        )
      );
    }
    return Container(child: 
      Row( children: rows ),
      padding: const EdgeInsets.only(top: 5, bottom: 5),
    );
  }

  Widget calendar() {
    // https://www.cnblogs.com/lxlx1798/p/11267411.html
    // DateTime firstDay = new DateTime(year, month, 1);//
    DateTime startDay = new DateTime(year, month, 1);//
    var span = Duration(days: (startDay.weekday * -1) + 1);
    startDay = startDay.add(span);
    List<Widget> cols = [];
    for(var i = 0; i < 6; i++) {
      List<Widget> rows = [];
      for(var j = 0; j < 7; j++) {
        rows.add(cell(startDay, i, j));
        span = Duration(days: 1);
        startDay = startDay.add(span);
      }
      cols.add(Expanded( flex: 1,
          child: Row(children: rows, mainAxisAlignment: MainAxisAlignment.spaceAround,)
        )
      );
      if(startDay.month != month) {
        break;
      }
    }
    // 
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: cols
    );
  }

  Widget cell(DateTime day, int top, int left){
    var s1 = DateFormat(fmtDate).format(day);
    var s2 = DateFormat(fmtDate).format(today);

    Text text1 = Text(DateFormat('d').format(day),
      style: TextStyle(
        fontSize: 18.0,
        color: year == day.year && month == day.month ? 
          (day.weekday > 5 ? Colors.orange[900] : Colors.black) : 
          Colors.grey
      )
    );
  
    var s3 = "", state = "";
    if(history != null && history.containsKey(s1)) {
      s3 = history[s1];
      state = "history";
    } else if(schedule != null && schedule.containsKey(s1)) {
      s3 = schedule[s1];
      state = "schedule";
    }
    // print("$state $s1 $s3");
    Text text2 = Text(s3,
      style: TextStyle(
        fontSize: 12.0,
        color: year == day.year && month == day.month 
          ? ( state == "history"
            ? (Colors.blue)
            : ( state == "today" || (state == "schedule" && s1.compareTo(s2) == 0)
              ? Colors.red : Colors.green
            )
          )
          : Colors.grey
      )
    );

    Widget stock = Stack(
      children: <Widget>[
        Align(
          child: text1,
          alignment: Alignment.topCenter,
        ),
        Align(
          child: text2,
          alignment: Alignment.bottomCenter,
        ),
        // Positioned(
        //   child: text,
        //   left: 0,
        //   top: 0
        // ),
        // Positioned(
        //   child: text1,
        //   bottom: 1,
        //   right: 1,
        // ),
      ],
      alignment: Alignment.center,
    );
    if(s1.compareTo(s2) > -1 && state != "history") {
      stock =  Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            DateTime day =  DateTime.now();
            if(day.day != today.day){
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: new Text("Schedule"),
                    content: new Text("更新日期"),
                    actions: <Widget>[
                      new FlatButton(
                        child: new Text("Ok"),
                        onPressed: () {
                          Navigator.of(context).pop();
                            today = DateTime.now();
                            setState(() {});
                        },
                      ),
                    ],
                  );
                }
              );
              return;
            }
            
            int hour = day.hour, minute = day.minute;
            if(s3.isNotEmpty) {
              var arr = s3.split(":");
              if(arr.length == 2) {
                hour = int.parse(arr[0]);
                minute = int.parse(arr[1]);
              }
            }

            TimeOfDay t = TimeOfDay(hour: hour, minute: minute);
            TimeOfDay time = await _showTimePicker(t);
            if(time == null) {
              // if(schedule != null)
              //   schedule.remove(s1);
            } else {
              var dt = DateTime(day.year, day.month, day.day, time.hour, time.minute);
              if(state == "today" || (state == "schedule" && s1.compareTo(s2) == 0)) { // 今天
                var _day =  DateTime.now();

                if(time.hour < _day.hour || (time.hour == _day.hour && time.minute <= _day.minute )){
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: new Text("Schedule"),
                        content: new Text("時間不正確"),
                        actions: <Widget>[
                          new FlatButton(
                            child: new Text("Ok"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ]
                      );
                    }
                  );
                  return;
                }
                setAlarm(today, time: time);
              } else if (state == "schedule" && history.containsKey(s2)){ 
                var dt2 = today.add(Duration(days: 1));
                // print("$s1 == ${DateFormat(fmtDate).format(dt2)} ");
                if(s1 == DateFormat(fmtDate).format(dt2)){
                  setAlarm(dt2, time: time);
                }
              }
              schedule[s1] = DateFormat(fmtTime).format(dt);
              storage.setItem("schedule", schedule);
              // print("$schedule");
              setState(() {});
            }
            // print("time: $time");
          },
          child: stock
        )
      );
    }
    BorderSide bs1 = BorderSide(width: 1.0, color: Colors.black12);
    BorderSide bs2 = BorderSide(width: 0, color: Colors.transparent);
  
    return Expanded(
      flex: 1,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: stock,
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: today.year == day.year && today.month == day.month && today.day == day.day 
            ? Colors.blue[50] : Colors.transparent,
          border: Border(top: top == 0 ? bs1 : bs2, left: left == 0 ? bs2 : bs1, bottom: bs1) ,
        )
      )
    );
  }

  Widget bntOK() {
    Widget child;
    var s = DateFormat(fmtDate).format(today);
    if(year == today.year && month == today.month && (history == null || !history.containsKey(s)) ) {
      child = Material(
        color: Colors.blue,
        child: InkWell(
          onTap: () {
            DateTime day =  DateTime.now();
            if(day.day != today.day){
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: new Text("Schedule"),
                    content: new Text("更新日期"),
                    actions: <Widget>[
                      new FlatButton(
                        child: new Text("Ok"),
                        onPressed: () {
                          Navigator.of(context).pop();
                            today = DateTime.now();
                            setState(() {});
                        },
                      ),
                    ],
                  );
                }
              );
              return;
            }

            history[s] = DateFormat(fmtTime).format(day);
            storage.setItem("history", history);
            export(history[s]);
            DateTime dt = new DateTime(today.year, today.month, today.day);//
            dt = dt.add(Duration(days: 1));
            setAlarm(dt);
            setState(() { });
          },
          child: Align(
            alignment: Alignment.center,
            child: Text("確定",
              textAlign: TextAlign.center,
              style: new TextStyle(
                fontSize: 20.0,
                color: Colors.white
              ),
            ),
          )
        )
      );
    }

    return Container(
      height: child == null ? 0 : 45.0,
      width: double.infinity,
      child: child
    );
  }
  void import() async {
    var s = DateFormat(fmtDate).format(today).substring(0, 6);
    String ret = await methodChannel.invokeMethod('readHistory', {
      "today": s
    });
    // print("import: $ret");
    if(ret != null) {
      history = {};
      var arr = ret.split("\n"); // 
      arr.forEach((item) {
        var arr2 = item.split("=");
        if(arr2.length == 2){
          print("${arr2[0]} ---- ${arr2[1]}");
          history[s + arr2[0]] = arr2[1];
        }
      });
      storage.setItem("history", history);
      setState(() {});
      print("$history");
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Schedule"),
            content: new Text("$s 月份沒有歷史資料!!"),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
      );
    }
  }

  void export(String value) async { // 備份 history
    var s = DateFormat(fmtDate).format(today);
    await methodChannel.invokeMethod('writeHistory', {
      "today": s.substring(0, 6),
      "value": s.substring(6) + "=" + value
    });
  }

  Future<TimeOfDay> _showTimePicker(TimeOfDay time) async {
    final TimeOfDay picked =
        await showTimePicker(context: context, initialTime: time);
    return picked;
  }

  void setup() async {
    var result = await showDialog <dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (_) => new Setup(mode: mode, hour: hh, minute: mm,
        buttons: [
          IButton(label: "匯入 $month 月份", onTap: (){
            Navigator.pop(context);
            import();
          }),
        ]
      )
    );
    // print("$result");
    if(result != null) {
      if(result["mode"] != mode || result["hour"] != hh || result["minute"] != mm) {
        mode = result["mode"];
        hh = result["hour"];
        mm = result["minute"];
        storage.setItem('mode', mode);
        storage.setItem('hour', hh);
        storage.setItem('minute', mm);
      }
    }
  }
}
