import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:much_todo/datepicker.dart';

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
                  new TextFormField(validator: (value) {
                    if (value.isEmpty) {
                      return "That is much todo about nothing!";
                    }
                  }, onSaved: (String todo) {
                    this._data.todo = todo;
                  }),
                  DateTimePicker(
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
                        }
                      ))
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
        body: new Center(
          child: new TodoForm(),
          ),
        );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var _data;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      drawer: buildDrawer(),
      body: new Center(
          child: buildTodoList()),
      floatingActionButton: new FloatingActionButton(
        onPressed: () => Navigator.push(context,
            new MaterialPageRoute(builder: (context) => new AddTasks())),
        tooltip: 'Add Todo',
        child: new Icon(Icons.add),
      ),
    );
  }

  _hzStart() {
    print("yes");
  }

  buildTodoList() {
    return new GestureDetector(
      onTap: () => print('tap'),
      onHorizontalDragStart: _hzStart(),
      child: new StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('todos')
            .orderBy("due", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Loading...');
          return new ListView(
              children: snapshot.data.documents.map<Widget>((DocumentSnapshot document) {
                return buildTodoRow(document);
            // return new ListTile(
            //     title: new Text(document['task']),
            //     subtitle: new Text(document['due'].toString()));
          }).toList());
        })
    );
  }

void delete(item) {
  if (_data.contains(item)) {
    _data.remove(item);
  }
}
Map<DismissDirection, double> _dismissThresholds() {
  Map<DismissDirection, double> map = new Map<DismissDirection, double>();
  map.putIfAbsent(DismissDirection.horizontal, () => 0.3);
  return map;
}
  buildTodoRow(DocumentSnapshot doc) {
     return new Dismissible(
      key: new Key(doc.documentID.toString()),
      direction: DismissDirection.horizontal,
      onDismissed: (DismissDirection direction) {
        print('delete ${doc.toString()}');
      },
      resizeDuration: null,
      dismissThresholds: _dismissThresholds(),
      // background: new LeaveBehindView(),
      child: new ListTile(
                title: new Text(doc['task']),
                subtitle: new Text(doc['due'].toString()))
      );
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
                Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => new AddTasks()));
              }),
          new ListTile(
            leading: const Icon(Icons.ac_unit),
            title: const Text('Filter Todos'),
          ),
          new ListTile(
            leading: const Icon(Icons.access_alarm),
            title: const Text('Set Reminders'),
          )
        ]),
      )));
  }
}
