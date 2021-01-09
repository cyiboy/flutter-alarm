import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'alarmRing.dart';
import 'notificationUtil.dart';
import 'storage.dart';
import 'receivedNotification.dart';

class AlarmsListPage extends StatefulWidget {
  AlarmsListPage({Key key}) : super(key: key);

  @override
  _AlarmsListPageState createState() => _AlarmsListPageState();
}

// TODO: add edit on tap: must-have
// TODO: change color if passed date of alarm(?): nice-to-have
class _AlarmsListPageState extends State<AlarmsListPage> {
  String _time;
  String _date;

  @override
  void initState() {
    super.initState();
    Timer.periodic(
        Duration(
          milliseconds: 50,
        ),
        (Timer t) => _getDateTime());
    _configureSelectNotificationSubject();
    _configureDidReceiveLocalNotificationSubject();
  }

  void _getDateTime() {
    var _dateTime = new DateTime.now();
    final String formattedDate =
        DateFormat('dd MMM').format(_dateTime).toString();
    final String formattedTime =
        DateFormat('kk:mm').format(_dateTime).toString();
    if (this.mounted) {
      setState(() {
        _time = formattedTime;
        _date = formattedDate;
      });
    }
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return ListTile(
      title: Text(document.get('name')),
      subtitle: Text(
        document.get('remarks') ?? 'No remarks',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          size: 20,
        ),
        highlightColor: Colors.redAccent,
        onPressed: () {
          Storage.deleteAlarm(document.id);
        },
      ),
      onTap: () {
        print("tapped");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF1F8FF),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 65.0, bottom: 5.0),
              child: Text(
                " $_date ",
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            Text(
              " $_time ",
              style: TextStyle(fontSize: 55.0),
            ),
            SizedBox(
              height: 20,
            ),
            StreamBuilder(
              stream: Storage.getStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: Text(
                    'no alarms yet',
                  ));
                }
                return Expanded(
                  child: ListView.builder(
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (context, index) => _buildListItem(
                          context, snapshot.data.documents[index])),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addAlarm');
        },
        child: Icon(Icons.add_alarm),
        backgroundColor: Colors.amber[400],
        elevation: 15,
      ),
    );
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => AlarmRingPage(payload: payload),
        ),
      );
    });
  }

  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      print("listening2");
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body)
              : null,
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        AlarmRingPage(payload: receivedNotification.payload),
                  ),
                );
              },
              child: const Text('Ok'),
            )
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }
}
