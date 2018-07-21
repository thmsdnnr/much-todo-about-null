import 'dart:core';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:much_todo/datepicker.dart';
import 'package:much_todo/editable_list_tile.dart';
import 'package:much_todo/helpers.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Much Todo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'about: nothing'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class TodoForm extends StatefulWidget {
  @override
  TodoFormState createState() {
    return TodoFormState();
  }
}

class _TodoData {
  String todo = '';
  bool completed = false;
  DateTime utcDateTime;
  serialize() => {
        'task': todo,
        'completed': completed,
        'due': utcDateTime,
      };
}

class _SubgoalData {
  final String subgoal;
  final bool completed;
  final bool isBlankSlate;
  final int order;
  final DocumentReference ref;
  _SubgoalData(
      {this.subgoal: '',
      this.completed: false,
      this.isBlankSlate: false,
      this.order,
      this.ref});
  Map<String, dynamic> toJson() => {
        'subgoal': subgoal,
        'completed': completed,
        'order': order,
      };
}

class TodoFormState extends State<TodoForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  _TodoData _data = _TodoData();
  DateTime _toDate = DateTime.now();
  TimeOfDay _toTime = TimeOfDay.now();
  bool isDue = false;
  void submit() {
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save();
      _formKey.currentState.reset();
      _data.utcDateTime = DateTime(_toDate.year, _toDate.month, _toDate.day,
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
    return Form(
        key: _formKey,
        child: Container(
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
                  TextFormField(
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
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: MaterialButton(
                          height: 50.0,
                          minWidth: 400.0,
                          color: Theme.of(context).primaryColorDark,
                          child: Text(
                            'do it!',
                            style: TextStyle(
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
    return Scaffold(
        appBar: AppBar(
          title: const Text("Let's Do This."),
        ),
        body: SafeArea(
          child: TodoForm(),
        ));
  }
}

class EditTask extends StatefulWidget {
  EditTask(this.task, this.documentId);
  final task;
  final documentId;
  @override
  _EditTaskState createState() => _EditTaskState();
}

class _EditTaskState extends State<EditTask> {
  // TODO: hold and drag to rearrange tasks
  // TODO: store ordinal task index
  // TODO: support task deletion
  // TODO: counter for # of complete tasks

  List<_SubgoalData> _subgoals = [];
  bool _isEditing = false;

  @override
  initState() {
    super.initState();
    getSubGoals();
  }

  Widget getFreshAddItem() {
    return EditableListTile(
      title: "Add A Subgoal",
      icon: Icons.add_box,
      clearOnEdit: true,
      isEditable: _isEditing,
      valueChangeHandler: (value) => setState(() {
            var newSubgoal = _SubgoalData(
              subgoal: value,
              order: _subgoals.length,
            );
            _subgoals.removeLast();
            _subgoals.add(newSubgoal);
            Firestore.instance
                .collection("todos")
                .document(widget.documentId)
                .collection("subgoals")
                .add(newSubgoal.toJson());
            _subgoals.add(_SubgoalData(isBlankSlate: true));
            getSubGoals();
          }),
    );
  }

  void getSubGoals() async {
    _SubgoalData fromDoc(doc) {
      return _SubgoalData(
        subgoal: doc.data['subgoal'],
        completed: doc.data['completed'],
        order: doc.data['order'],
        ref: doc.reference,
      );
    }

    await Firestore.instance
        .collection("todos")
        .document(widget.documentId)
        .collection("subgoals")
        .getDocuments()
        .then((data) {
      setState(() {
        _subgoals = data.documents.map((doc) => fromDoc(doc)).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        _subgoals.add(_SubgoalData(isBlankSlate: true));
      });
    });
  }

  ListView getTheList(List<_SubgoalData> subgoals) {
    return ListView.builder(
        itemCount: subgoals.length,
        itemBuilder: (_, int index) {
          final sub = _subgoals[index];
          return sub.isBlankSlate
              ? _isEditing ? getFreshAddItem() : null
              : ListTile(
                  leading: _isEditing
                      ? IconButton(
                          icon: Icon(Icons.arrow_upward),
                          onPressed: () {
                            Firestore.instance
                                .collection("todos")
                                .document(widget.documentId)
                                .collection("subgoals")
                                .document(sub.ref.documentID)
                                .updateData({"order": min(0, index - 1)});
                            setState(() {
                              if (index > 0) {
                                var temp = _subgoals[index - 1];
                                _subgoals[index - 1] = _subgoals[index];
                                _subgoals[index] = temp;
                              }
                            });
                          })
                      : null,
                  title: EditableListTile(
                    title: sub.subgoal,
                    subtitle: sub.subgoal,
                    clearOnEdit: false,
                    isEditable: _isEditing,
                    isCompleted: sub.completed,
                    valueChangeHandler: (newSubgoal, index) {
                      setState(() {
                        DocumentReference ref = sub.ref;
                        _SubgoalData theNewSubgoal = _SubgoalData(
                            subgoal: newSubgoal, order: min(0, index - 1));
                        _subgoals[index] = theNewSubgoal;
                        Firestore.instance
                            .collection("todos")
                            .document(widget.documentId)
                            .collection("subgoals")
                            .document(ref.documentID)
                            .updateData(theNewSubgoal.toJson());
                      });
                    },
                    completionChangeHandler: () {
                      bool completionStatus = !sub.completed;
                      DocumentReference ref = sub.ref;
                      Firestore.instance
                          .collection("todos")
                          .document(widget.documentId)
                          .collection("subgoals")
                          .document(ref.documentID)
                          .updateData({"completed": completionStatus});
                      getSubGoals();
                    },
                  ),
                );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.task['task']),
          actions: <Widget>[
            IconButton(
              icon: _isEditing
                  ? Icon(Icons.subdirectory_arrow_left)
                  : Icon(Icons.edit),
              onPressed: () => setState(() {
                    _isEditing = !_isEditing;
                  }),
            )
          ],
        ),
        body: SafeArea(child: getTheList(_subgoals)));
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var _showCompleted = false;
  var _showDeleted = false;
  var _completed;
  var _total;
  var _ongoing;
  var _timeFilterDuration = "Today";
  var _undoAction;

  final String _menuValue1 = 'Completed';
  final String _menuValue2 = 'Ongoing';

  final String _duration1 = 'Today';
  final String _duration2 = 'This Week';
  final String _duration3 = 'Past Due';

  static Query baseQuery =
      Firestore.instance.collection('todos').orderBy("due", descending: false);

  Map<String, Query> _durationToQuery = {
    "Today": baseQuery
        .where("due", isGreaterThanOrEqualTo: DateTime.now())
        .where("due",
            isLessThanOrEqualTo: DateTime.now().add(Duration(days: 1))),
    "This Week": baseQuery
        .where("due", isGreaterThanOrEqualTo: DateTime.now())
        .where("due",
            isLessThanOrEqualTo: DateTime.now().add(Duration(days: 7))),
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

  @override
  Widget build(BuildContext context) {
    var _title = _showCompleted
        ? "DONE: $_timeFilterDuration"
        : "DOING: $_timeFilterDuration";
    return Scaffold(
      appBar: AppBar(title: Text(_title), actions: <Widget>[
        PopupMenuButton<String>(
          icon: Icon(Icons.filter_list),
          onSelected: showMenuSelection,
          itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                PopupMenuItem<String>(value: _duration1, child: Text('Today')),
                PopupMenuItem<String>(
                    value: _duration2, child: Text('This Week')),
                PopupMenuItem<String>(
                    value: _duration3, child: Text('Past Due')),
              ],
        ),
        PopupMenuButton<String>(
          onSelected: showMenuSelection,
          itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                PopupMenuItem<String>(
                    value: _menuValue1, child: Text('Completed ($_completed)')),
                PopupMenuItem<String>(
                    value: _menuValue2, child: Text('In Progress ($_ongoing)')),
              ],
        )
      ]),
      body: buildTodoList(grabTodos),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => AddTasks())),
        tooltip: 'Add Todo',
        child: Icon(Icons.add),
      ),
    );
  }

  grabTodos() {
    return _durationToQuery[_timeFilterDuration].snapshots();
  }

  buildTodoList(stream) {
    return Center(
        child: GestureDetector(
            child: StreamBuilder<QuerySnapshot>(
                stream: stream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text('Loading...');
                  _completed = snapshot.data.documents
                      .where((doc) => doc['completed'])
                      .length;
                  _total = snapshot.data.documents
                      .where((doc) => doc['deletedAt'] == null)
                      .length;
                  _ongoing = _total - _completed;
                  return ListView(
                      children: snapshot.data.documents
                          .where((doc) => doc['completed'] == _showCompleted)
                          .where((doc) => _showDeleted
                              ? doc['deletedAt'] != null
                              : doc['deletedAt'] == null)
                          .map<Widget>((DocumentSnapshot document) {
                    return buildTodoRow(document);
                  }).toList());
                })));
  }

  Map<DismissDirection, double> _dismissThresholds() {
    Map<DismissDirection, double> map = Map<DismissDirection, double>();
    map.putIfAbsent(DismissDirection.horizontal, () => 0.3);
    return map;
  }

  buildTodoRow(DocumentSnapshot doc) {
    // TODO: display count of subgoals / completion count
    // TODO: display tags for task type
    final ThemeData theme = Theme.of(context);
    return Builder(builder: (BuildContext context) {
      return Dismissible(
          key: Key(doc.documentID.toString()),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) =>
              _handleTodoItemDismiss(direction, doc, context),
          resizeDuration: null,
          dismissThresholds: _dismissThresholds(),
          background: Container(
              color: theme.errorColor,
              child: const ListTile(
                  contentPadding: EdgeInsets.only(top: 4.0, left: 16.0),
                  leading: const Icon(Icons.delete,
                      color: Colors.white, size: 36.0))),
          secondaryBackground: Container(
              color: theme.primaryColorLight,
              child: const ListTile(
                  contentPadding: EdgeInsets.only(top: 4.0, right: 16.0),
                  trailing: const Icon(Icons.check,
                      color: Colors.white, size: 36.0))),
          child: ListTile(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditTask(doc, doc.documentID))),
              title: Text(doc['task']),
              subtitle: Text("${formatDate(doc['due'])}")));
    });
  }

  buildDrawer() {
    return Drawer(
        child: SafeArea(
            child: Container(
      margin: const EdgeInsets.all(20.0),
      child: Column(children: <Widget>[
        ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Todo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => AddTasks()));
            }),
        ListTile(
            leading: const Icon(Icons.ac_unit),
            title: Text(_showCompleted == true ? 'In Progress' : 'Completed'),
            onTap: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
              Navigator.pop(context);
            }),
        ListTile(
          leading: const Icon(Icons.access_alarm),
          title: const Text('Set Reminders'),
        )
      ]),
    )));
  }

  _handleTodoItemDismiss(DismissDirection direction, doc, context) {
    final String action =
        (direction == DismissDirection.endToStart) ? 'completed' : 'deleted';
    Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('You $action the task!'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => _undoAction(),
        )));
    if (direction == DismissDirection.endToStart) {
      // Completion
      Firestore.instance.runTransaction((transaction) async {
        DocumentSnapshot freshSnap = await transaction.get(doc.reference);
        var payload = _showCompleted
            ? {
                'completed': false,
                'completed_at': null,
              }
            : {
                'completed': true,
                'completed_at': DateTime.now(),
              };
        await transaction.update(freshSnap.reference, payload);
      });
      _undoAction = () async {
        Firestore.instance.runTransaction((transaction) async {
          DocumentSnapshot freshSnap = await transaction.get(doc.reference);
          var payload = _showCompleted
              ? {
                  'completed': true,
                }
              : {
                  'completed': false,
                  'completed_at': null,
                };
          await transaction.update(freshSnap.reference, payload);
        });
      };
    }
    if (direction == DismissDirection.startToEnd) {
      // Deletion
      Firestore.instance.runTransaction((transaction) async {
        DocumentSnapshot freshSnap = await transaction.get(doc.reference);
        var payload = _showDeleted
            ? {
                'deletedAt': null,
              }
            : {
                'deletedAt': DateTime.now(),
              };
        await transaction.update(freshSnap.reference, payload);
      });
      _undoAction = () async {
        Firestore.instance.runTransaction((transaction) async {
          DocumentSnapshot freshSnap = await transaction.get(doc.reference);
          var payload = _showDeleted
              ? {
                  'deletedAt': DateTime.now(),
                }
              : {
                  'deletedAt': null,
                };
          await transaction.update(freshSnap.reference, payload);
        });
      };
    }
  }
}
