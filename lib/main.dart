import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:much_todo/datepicker.dart';
import 'dart:core';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Much Todo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'about: nothing'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class TodoForm extends StatefulWidget {
  @override
  TodoFormState createState() {
    return new TodoFormState();
  }
}

class _TodoData {
  String todo = '';
  bool completed = false;
  DateTime dueDate;
  TimeOfDay dueTime;
  DateTime utcDateTime;
  serialize() => {'task': todo, 'completed': completed, 'due': utcDateTime};
}

class TodoFormState extends State<TodoForm> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  _TodoData _data = new _TodoData();
  DateTime _toDate = new DateTime.now();
  TimeOfDay _toTime = const TimeOfDay(hour: 7, minute: 28);
  bool isDue = false;
  void submit() {
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save();
      _formKey.currentState.reset();
      _data.utcDateTime = new DateTime(_toDate.year, _toDate.month, _toDate.day,
          _toTime.hour, _toTime.minute);
      Firestore.instance
          .collection('todos')
          .document()
          .setData(_data.serialize());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Form(
        key: _formKey,
        child: new Container(
            height: 250.0,
            margin: EdgeInsets.only(left: 16.0, right: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new TextFormField(
                      autofocus: true,
                      validator: (value) {
                        if (value.isEmpty) {
                          return "That is much todo about nothing!";
                        }
                      },
                      onSaved: (String todo) {
                        this._data.todo = todo;
                      }),
                  DateTimePicker(
                    // TODO: make dropdown with "Today" / "Tomorrow" / etc
                    // more specific calendar icon to launch the DateTimePicker
                    // preferences to set "EOD" midnight, 5pm etc
                    labelText: 'Due Date',
                    selectedDate: _toDate,
                    selectedTime: _toTime,
                    selectDate: (DateTime date) {
                      setState(() {
                        _toDate = date;
                      });
                    },
                    selectTime: (TimeOfDay time) {
                      setState(() {
                        _toTime = time;
                      });
                    },
                  ),
                  new Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: new MaterialButton(
                          height: 50.0,
                          minWidth: 400.0,
                          color: Theme.of(context).primaryColorDark,
                          child: new Text(
                            'do it!',
                            style: new TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 24.0,
                              letterSpacing: 1.0,
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              submit();
                            }
                          }))
                ])));
  }
}

class AddTasks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Let's Do This."),
        ),
        body: new SafeArea(
          child: new TodoForm(),
        ));
  }
}

class _MyHomePageState extends State<MyHomePage> {
  // TODO: add "todo dashboard" to front page with a graph thing or whatevs
  // TODO: time estimates "that's ambitious", etc.
  // TODO: add login
  // TODO: add todo list export / e-mail reminders / text reminders
  // TODO: system notifications https://pub.dartlang.org/packages/firebase_messaging
  var _showCompleted = false;
  var _completed;
  var _total;
  var _ongoing;
  var _timeFilterDuration = "Today";

  final String _menuValue1 = 'Completed';
  final String _menuValue2 = 'Ongoing';

  final String _duration1 = 'Today';
  final String _duration2 = 'This Week';
  final String _duration3 = 'Past Due';

  static Query baseQuery = Firestore.instance
    .collection('todos')
    .orderBy("due", descending: false);

  Map<String, Query> _durationToQuery = {
    "Today": baseQuery.where("due", isGreaterThanOrEqualTo: DateTime.now())
      .where("due", isLessThanOrEqualTo: DateTime.now().add(Duration(days: 1))),
    "This Week": baseQuery.where("due", isGreaterThanOrEqualTo: DateTime.now())
      .where("due", isLessThanOrEqualTo: DateTime.now().add(Duration(days: 7))),
    "Past Due": baseQuery.where("due", isLessThanOrEqualTo: DateTime.now()),
  };

  void showMenuSelection(String value) {
    if (<String>[_menuValue1, _menuValue2].contains(value)) if (value ==
        "Completed") {
      setState(() {
        _showCompleted = true;
      });
    } else {
      setState(() {
        _showCompleted = false;
      });
    }
    if (<String>[_duration1, _duration2, _duration3].contains(value)) {
      setState(() {
        _timeFilterDuration = value;
      });
    }
  }

  Duration diffDate(date) {
    Duration difference = date.difference(DateTime.now());
    return difference;
  }

  String formatDate(date) {
    Duration difference = diffDate(date);
    final hasPassed = difference.isNegative == true;
    final suffix = hasPassed ? "ago" : "away";

    final weeks =
        difference.inDays.abs() > 7 ? (difference.inDays.abs() / 7).floor() : 0;
    final weekString =
        weeks == 0 ? "" : weeks > 1 ? "$weeks weeks" : weeks > 0 ? "$weeks week" : "";
    final hours =
        difference.inHours.abs() < 24 ? difference.inHours.abs().floor() : 0;
    final hoursString =
        hours == 0 ? "" : hours > 1 ? "$hours hours" : hours > 0 ? "$hours hour" : "";
    final minutes =
        difference.inSeconds.abs() < 3600 ? (difference.inSeconds.abs()/60).floor() : 0;
    final minutesString =
        hours !=0 && hours > 1 ? "" : minutes > 1 ? "$minutes minutes" : minutes > 0 ? "$minutes minute" : "";
    final days =
        difference.inDays.abs() < 7 ? difference.inDays.abs().floor() : 0;
    final dayString = days == 0 ? "" : days > 1 ? "$days days" : days > 0 ? "$days day" : "";

    return "$weekString$dayString$hoursString$minutesString $suffix";
  }

  @override
  Widget build(BuildContext context) {
    // TODO: add button to sort asc/desc
    // TODO: add button to filter ()
    var _title = _showCompleted ? "DONE: $_timeFilterDuration" : "DOING: $_timeFilterDuration";
    return new Scaffold(
      appBar: new AppBar(title: new Text(_title), actions: <Widget>[
        PopupMenuButton<String>(
          icon: Icon(Icons.filter_list),
          onSelected: showMenuSelection,
          itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                PopupMenuItem<String>(
                    value: _duration1,
                    child: Text('Today')),
                PopupMenuItem<String>(
                    value: _duration2,
                    child: Text('This Week')),
                PopupMenuItem<String>(
                    value: _duration3,
                    child: Text('Past Due')),
              ],
        ),
        PopupMenuButton<String>(
          onSelected: showMenuSelection,
          itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                new PopupMenuItem<String>(
                    value: _menuValue1,
                    child: new Text('Completed ($_completed)')),
                new PopupMenuItem<String>(
                    value: _menuValue2,
                    child: new Text('In Progress ($_ongoing)')),
              ],
        )
      ]),
      body: buildTodoList(grabTodos),
      floatingActionButton: new FloatingActionButton(
        onPressed: () => Navigator.push(context,
            new MaterialPageRoute(builder: (context) => new AddTasks())),
        tooltip: 'Add Todo',
        child: new Icon(Icons.add),
      ),
    );
  }

  grabTodos() {
    return _durationToQuery[_timeFilterDuration].snapshots();
  }

  buildTodoList(stream) {
    return new Center(
        child: GestureDetector(
            child: new StreamBuilder<QuerySnapshot>(
                stream: stream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text('Loading...');
                  _completed = snapshot.data.documents
                      .where((doc) => doc['completed'])
                      .length;
                  _total = snapshot.data.documents.length;
                  _ongoing = _total - _completed;
                  return new ListView(
                      children: snapshot.data.documents
                          .where((doc) => doc['completed'] == _showCompleted)
                          .map<Widget>((DocumentSnapshot document) {
                    return buildTodoRow(document);
                  }).toList());
                })));
  }

  Map<DismissDirection, double> _dismissThresholds() {
    Map<DismissDirection, double> map = new Map<DismissDirection, double>();
    map.putIfAbsent(DismissDirection.horizontal, () => 0.3);
    return map;
  }

  buildTodoRow(DocumentSnapshot doc) {
    // TODO: make build Todo Row have ability to show child items
    // TODO: chips
    // TODO: progress bar
    // TODO: conditional / color formatting
    final ThemeData theme = Theme.of(context);
    return new Builder(builder: (BuildContext context) {
      return new Dismissible(
          key: new Key(doc.documentID.toString()),
          direction: DismissDirection.horizontal,
          onDismissed: (DismissDirection direction) {
            final String action = (direction == DismissDirection.endToStart)
                ? 'completed'
                : 'deleted';
            Scaffold.of(context).showSnackBar(new SnackBar(
                content: new Text('You $action the task!'),
                action: new SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      print('Please implement undo!');
                    } // TODO: implement undo
                    )));
            if (direction == DismissDirection.endToStart) {
              // Completion
              Firestore.instance.runTransaction((transaction) async {
                DocumentSnapshot freshSnap =
                    await transaction.get(doc.reference);
                var payload = _showCompleted
                    ? {
                        'completed': false,
                        'completed_at': null,
                      }
                    : {
                        'completed': true,
                        'completed_at': new DateTime.now(),
                      };
                await transaction.update(freshSnap.reference, payload);
              });
            }
            if (direction == DismissDirection.startToEnd) {
              // TODO: implement deletion / archiving
              print('Deleted. Please implement!');
            }
          },
          resizeDuration: null,
          dismissThresholds: _dismissThresholds(),
          background: new Container(
              color: theme.errorColor,
              child: const ListTile(
                  contentPadding: EdgeInsets.only(top: 4.0, left: 16.0),
                  leading: const Icon(Icons.delete,
                      color: Colors.white, size: 36.0))),
          secondaryBackground: new Container(
              color: theme.primaryColorLight,
              child: const ListTile(
                  contentPadding: EdgeInsets.only(top: 4.0, right: 16.0),
                  trailing: const Icon(Icons.check,
                      color: Colors.white, size: 36.0))),
          child: new ListTile(
              title: new Text(doc['task']),
              subtitle: new Text(
                  "${formatDate(doc['due'])}")));
    });
  }

  buildDrawer() {
    return new Drawer(
        child: new SafeArea(
            child: new Container(
      margin: const EdgeInsets.all(20.0),
      child: new Column(children: <Widget>[
        new ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Todo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  new MaterialPageRoute(builder: (context) => new AddTasks()));
            }),
        new ListTile(
            leading: const Icon(Icons.ac_unit),
            title:
                new Text(_showCompleted == true ? 'In Progress' : 'Completed'),
            onTap: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
              Navigator.pop(context);
            }),
        new ListTile(
          leading: const Icon(Icons.access_alarm),
          title: const Text('Set Reminders'),
        )
      ]),
    )));
  }
}
