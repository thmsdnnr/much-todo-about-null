import 'package:flutter/material.dart';

class EditableListTile extends StatefulWidget {
  const EditableListTile({
    this.title,
    this.subtitle,
    this.labelText,
    this.valueChangeHandler,
    this.completionChangeHandler,
    this.keyboardType = TextInputType.text,
    this.clearOnEdit = false,
    this.icon = Icons.edit,
    this.isEditable,
    this.isCompleted = false,
  });

  final title;
  final subtitle;
  final labelText;
  final valueChangeHandler;
  final keyboardType;
  final clearOnEdit;
  final icon;
  final isEditable;
  final isCompleted;
  final completionChangeHandler;

  @override
  _EditableListTileState createState() => _EditableListTileState();
}

class _EditableListTileState extends State<EditableListTile> {
  bool _isEditing = false;
  String _currentValue;
  TextEditingController _textController = TextEditingController();

  void handleEditComplete() {
    setState(() {
      _isEditing = false;
      String _newValue = _textController.text.toString();
      if (_currentValue != _newValue && _newValue != "") {
        widget.valueChangeHandler(_newValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 8.0, right: 8.0),
        margin: EdgeInsets.only(top: 8.0, left: 24.0, right: 24.0),
        child: widget.isEditable == true
            ? _isEditing == true ? editingAcitve() : editingReadOnly()
            : displayOnly());
  }

  Widget editingAcitve() {
    return Padding(
      padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
      child: TextField(
          autofocus: true,
          keyboardType: widget.keyboardType,
          onSubmitted: (string) => handleEditComplete(),
          controller: _textController,
          decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: widget.labelText,
              suffixIcon: GestureDetector(
                child: Icon(Icons.done),
                onTap: () => handleEditComplete(),
              ))),
    );
  }

  Widget editingReadOnly() {
    return ListTile(
      onTap: () {
        setState(() {
          _isEditing = true;
          _currentValue = widget.subtitle;
          _textController.text = widget.subtitle;
          if (widget.clearOnEdit == true) {
            _textController.clear();
          }
        });
      },
      title: Text(widget.title),
      trailing: IconButton(
          icon: Icon(widget.icon),
          onPressed: () {
            setState(() {
              _isEditing = true;
              _currentValue = widget.subtitle;
              _textController.text = widget.subtitle;
              if (widget.clearOnEdit == true) {
                _textController.clear();
              }
            });
          }),
    );
  }

  final completedStyle = TextStyle(
    decoration: TextDecoration.lineThrough,
    decorationColor: Colors.redAccent,
  );

  Widget displayOnly() {
    return ListTile(
      title: Text(
        widget.title,
        style: widget.isCompleted ? completedStyle : null,
      ),
      leading: widget.isCompleted
          ? null
          : IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                widget.completionChangeHandler();
              }),
    );
  }
}
