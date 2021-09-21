import 'package:flutter/material.dart';
import 'package:smart_accounting/data.dart';
import 'package:smart_accounting/utils.dart';

class SettingsPage extends StatefulWidget {
  final AccountData? accountData;
  final AnalyzedAccountData? analyzedAccountData;

  SettingsPage({required this.accountData, required this.analyzedAccountData});

  @override
  State<StatefulWidget> createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends State<SettingsPage> {
  List<TextEditingController> _keycontrollers = [];
  List<TextEditingController> _valuecontrollers = [];

  @override
  void initState() {
    super.initState();
  }

  bool _updateLock = false;

  void _update() {
    if (_updateLock) return;
    _updateLock = true;
    var originalLength = widget.accountData?.categories.length;
    widget.accountData?.categories = [];
    for (var i = 0; i < _keycontrollers.length; i++) {
      if (_keycontrollers[i].text.isNotEmpty ||
          _valuecontrollers[i].text.isNotEmpty) {
        widget.accountData?.categories
            .add([_keycontrollers[i].text, _valuecontrollers[i].text]);
      }
    }
    if (originalLength == widget.accountData?.categories.length) {
      _updateLock = false;
      return;
    }
    refresh();
    _updateLock = false;
  }

  void refresh() {
    for (var i = 0; i < (widget.accountData?.categories.length ?? 0); i++) {
      getKeyControllerAtIndex(i).text =
          widget.accountData?.categories[i][0] ?? "";
      getValueControllerAtIndex(i).text =
          widget.accountData?.categories[i][1] ?? "";
    }
    var length = widget.accountData?.categories.length ?? 0;
    getKeyControllerAtIndex(length).text = "";
    getValueControllerAtIndex(length).text = "";
    setState(() {});
  }

  TextEditingController getKeyControllerAtIndex(int index,
      {String? defaultText}) {
    while (_keycontrollers.length <= index) {
      _keycontrollers.add(TextEditingController());
      if (_keycontrollers.length == index + 1) {
        if (defaultText != null) {
          _keycontrollers[index].text = defaultText;
        }
        _keycontrollers[index].addListener(_update);
      }
    }
    return _keycontrollers[index];
  }

  TextEditingController getValueControllerAtIndex(int index,
      {String? defaultText}) {
    while (_valuecontrollers.length <= index) {
      _valuecontrollers.add(TextEditingController());
      if (_valuecontrollers.length == index + 1) {
        if (defaultText != null) {
          _valuecontrollers[index].text = defaultText;
        }
        _valuecontrollers[index].addListener(_update);
      }
    }
    return _valuecontrollers[index];
  }

  @override
  void dispose() {
    for (var controller in _keycontrollers) {
      controller.dispose();
    }
    for (var controller in _valuecontrollers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(onPressed: refresh, icon: Icon(Icons.refresh), iconSize: 20),
        Expanded(
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: ListView.builder(
                  itemCount: (widget.accountData?.categories.length ?? 0) + 1,
                  itemBuilder: (context, i) {
                    if (i == widget.accountData?.categories.length) {
                      final keycontroller = getKeyControllerAtIndex(i);
                      final valuecontroller = getValueControllerAtIndex(i);
                      return Container(
                          height: 30,
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    width: 300,
                                    child: TextField(
                                        controller: keycontroller,
                                        decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            isCollapsed: true,
                                            contentPadding:
                                                EdgeInsets.all(8.0)))),
                                Container(width: 10),
                                Container(
                                  width: 300,
                                  child: TextField(
                                      controller: valuecontroller,
                                      decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          isCollapsed: true,
                                          contentPadding: EdgeInsets.all(8.0))),
                                ),
                              ]));
                    }
                    final entry = widget.accountData?.categories[i];
                    final keycontroller =
                        getKeyControllerAtIndex(i, defaultText: entry?[0]);
                    final valuecontroller =
                        getValueControllerAtIndex(i, defaultText: entry?[1]);
                    return Container(
                      height: 30,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: 300,
                                child: TextField(
                                    controller: keycontroller,
                                    decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        isCollapsed: true,
                                        contentPadding: EdgeInsets.all(8.0)))),
                            Container(width: 10),
                            Container(
                                width: 300,
                                child: TextField(
                                    controller: valuecontroller,
                                    decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        isCollapsed: true,
                                        contentPadding: EdgeInsets.all(8.0)))),
                          ]),
                    );
                  })),
        ),
      ],
    );
  }
}
