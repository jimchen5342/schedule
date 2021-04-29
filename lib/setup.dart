import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IButton {
  String label;
  Function onTap;
  Color color;
  IButton({@required this.label, this.onTap, this.color});
}

class Setup extends StatefulWidget {
  int hour = 21, minute = 30, mode = 0;
  List<IButton> buttons = [];
  Setup({Key key, this.hour, this.minute,  this.mode, this.buttons}) : super(key: key);
 
  @override
  State<StatefulWidget> createState() => SetupState();
}

class SetupState extends State<Setup> {

  @override
  Widget build(BuildContext context) {
    List<Widget> cols = [
      _header(context), 
      _body(context),
      _footer(context)
    ];

    return new Padding(
      padding: const EdgeInsets.all(5.0),
      child: new Material(
        type: MaterialType.transparency,
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Container(
              width: 300,
              decoration: ShapeDecoration(
                color: Color(0xffffffff),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
              ),
              margin: const EdgeInsets.all(5.0),
              child: new Column(
                children: cols,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(context){
    return Container(
      // key: _key,
      padding: const EdgeInsets.all(10.0),
      child: new Row(
        children: <Widget>[
          new Expanded( 
            flex: 1,
            child: new Text( "設定",
              style: new TextStyle(
                color: Color(0xffe0e0e0),
                fontSize: 19.0,
              ),
            ),
          ),
          new InkWell(
            onTap: (){
              Navigator.pop(context);
              // widget.onClose();
            },
            child: new Padding(
              padding: const EdgeInsets.all(5.0),
              child: new Icon(
                Icons.close,
                color: Color(0xffe0e0e0),
              ),
            ),
          ),
        ],
      ),
      // decoration: BoxDecoration( border:  Border(bottom: bs) ),
      decoration: ShapeDecoration(
        color: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8.0),
            topRight: Radius.circular(8.0)
          ),
        ),
      ),
      // color: Colors.blue,
    );
  }

  Widget _body(context){
    Widget widget1 = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Radio(
          value: widget.mode,
          onChanged: (value) {
            widget.mode = 0;
            setState(() {});
          },
          groupValue: 0,
          activeColor: Colors.red,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Container(
          width: 100.0,
          child:  InkWell(
            onTap: () {
              widget.mode = 0;
              setState(() {});
            }, 
            child: Text( "上班日",
              style: new TextStyle(
                // color: Colors.white,
                fontSize: 20.0,
              ),
            ),
          ),
        )
      ]
    );

    var dt = DateTime(2020, 1, 1, widget.hour, widget.minute);
    var s = DateFormat("HH:mm").format(dt); // 不存 storage
    Widget widget2 = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Radio(
          value: widget.mode,
          onChanged: (value) {
            _showTimePicker();
          },
          groupValue: 1,
          activeColor: Colors.red,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Container(
          width: 100.0,
          child:  InkWell(
            onTap: () {
              _showTimePicker();
            }, 
            child: Text( "$s",
              style: new TextStyle(
                // color: Colors.white,
                fontSize: 20.0,
              ),
            ),
          ),
        )
      ]
    );

    return new Container(
      constraints: BoxConstraints(minHeight: 100.0, maxHeight: 500),
      child: new Padding(
        padding: const EdgeInsets.all(12.0),
        child: new IntrinsicHeight(
          child: SingleChildScrollView(
            child:  new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                widget1, widget2
              ]
            )
          ),
        ),
      ),
    );
  }

  Widget _footer(context){ // 只是為了可以用，沒什麼最佳化
    List<IButton> mybtn = [];
    widget.buttons.forEach((item) {
      mybtn.add(item);
    });

    // if(widget.buttons.length == 1) {
    //   widget.buttons.add(
    //     IButton(label: "確定", onTap: (){
    //       var obj = {"mode": widget.mode, "hour": widget.hour, "minute": widget.minute};
    //       Navigator.of(context).pop(obj);
    //       // widget.onClose(obj);
    //     })
    //   );      
    // }

    mybtn.add(
      IButton(label: "確定", onTap: (){
        var obj = {"mode": widget.mode, "hour": widget.hour, "minute": widget.minute};
        Navigator.of(context).pop(obj);
        // widget.onClose(obj);
      })
    );

    List<Widget> btns = [];

    for(var i = 0; i < mybtn.length; i++){
      btns.add(
        Expanded(
          flex: 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                mybtn[i].onTap();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                child: new Text(mybtn[i].label,
                  textAlign: TextAlign.center,
                  style: new TextStyle(
                    fontSize: 18.0,
                    color: mybtn[i].color ?? Colors.blue
                  ),
                ),
                decoration: BoxDecoration(
                  // color: sleepMinutes == arr[i] ? Colors.blue[400] : Colors.white,
                  // border:  Border(top: BorderSide(width: 2.0, color: Colors.black12), bottom: null )
                )
              )
            )
          )
        )
      );
    }
    return Container(
      // padding: const EdgeInsets.only(top: 10),
      height: 55, 
      width: double.infinity,
      child: Row(children: btns),
      // decoration: BoxDecoration( border:  Border(top: bs) ),
    );
  }

  _showTimePicker() async {
    TimeOfDay time = TimeOfDay(hour: widget.hour, minute: widget.minute);
    final TimeOfDay picked =
        await showTimePicker(context: context, initialTime: time);
    if(picked != null) {
      widget.hour = picked.hour;
      widget.minute = picked.minute;
    } 
    widget.mode = 1;
    setState(() {});
  }
}