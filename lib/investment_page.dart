import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils.dart';
import 'data.dart';

class InvestmentPage extends StatefulWidget {
  final List<Investment> investments;
  final List<FixedInvestmentAccount> fixedInvestments;
  final List<FluctuateInvestmentAccount> fluctuateInvestments;
  final List<int> filteredFixedInvestment;
  final List<int> filteredFluctuateInvestment;
  final int pageSize;
  final VoidCallback refresh;
  final VoidCallback updateFixedInvestmentFiltered;
  final VoidCallback updateFluctuateInvestmentFiltered;
  final void Function(bool? value) changeShowEmpty;
  final void Function(bool? value) changeShowExpired;
  final void Function(int index, bool ascend) onSortFixedTable;
  final void Function(int index, bool ascend) onSortFluctuateTable;
  final int sortFixedInvestmentColumn;
  final bool sortFixedInvestmentAscending;
  final int sortFluctuateInvestmentColumn;
  final bool sortFluctuateInvestmentAscending;
  final bool showExpired;
  final bool showEmpty;

  InvestmentPage(
      {Key? key,
      this.pageSize = 15,
      required this.investments,
      required this.fixedInvestments,
      required this.fluctuateInvestments,
      required this.filteredFixedInvestment,
      required this.filteredFluctuateInvestment,
      required this.refresh,
      required this.updateFixedInvestmentFiltered,
      required this.updateFluctuateInvestmentFiltered,
      required this.changeShowEmpty,
      required this.changeShowExpired,
      required this.onSortFixedTable,
      required this.onSortFluctuateTable,
      required this.sortFixedInvestmentAscending,
      required this.sortFixedInvestmentColumn,
      required this.sortFluctuateInvestmentAscending,
      required this.sortFluctuateInvestmentColumn,
      required this.showExpired,
      required this.showEmpty})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _InvestmentPageState();
  }
}

class _InvestmentPageState extends State<InvestmentPage> {
  int investmentShowPageType = 0;
  int fixedInvestmentPageIndex = 0;
  int fluctuateInvestmentPageIndex = 0;
  TextEditingController? _jumpToFixedInvestmentPageController;
  TextEditingController? _jumpToFluctuateInvestmentPageController;
  TextEditingController? _updateInvestmentNameController;
  TextEditingController? _newInvestmentNameController;
  TextEditingController? _updateInvestmentRateController;
  TextEditingController? _updateInvestmentCurrentValueController;
  int updateInvestmentType = 0;
  bool interestBeforeEnd = false;

  int? selectedInvestmentIndex;
  DateTime updateInvestmentStart = DateTime.now();
  DateTime? updateInvestmentEnd;

  int get maxFixedInvestmentPageIndex {
    return (widget.filteredFixedInvestment.length - 1) ~/ widget.pageSize;
  }

  int get maxFluctuateInvestmentPageIndex {
    return (widget.filteredFluctuateInvestment.length - 1) ~/ widget.pageSize;
  }

  @override
  void initState() {
    super.initState();
    _jumpToFixedInvestmentPageController = TextEditingController();
    _jumpToFluctuateInvestmentPageController = TextEditingController();
    _updateInvestmentNameController = TextEditingController();
    _updateInvestmentNameController?.addListener(() {
      _onUpdateSelectInvestmentName(_updateInvestmentNameController?.text);
    });
    _newInvestmentNameController = TextEditingController();
    _updateInvestmentRateController = TextEditingController();
    _updateInvestmentCurrentValueController = TextEditingController();
  }

  @override
  void dispose() {
    _jumpToFixedInvestmentPageController?.dispose();
    _jumpToFluctuateInvestmentPageController?.dispose();
    _updateInvestmentNameController?.dispose();
    _newInvestmentNameController?.dispose();
    _updateInvestmentRateController?.dispose();
    _updateInvestmentCurrentValueController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        _InvestmentLeftSide(
          selectNameController: _updateInvestmentNameController,
          updateInvestmentRateController: _updateInvestmentRateController,
          updateCurrentValueController: _updateInvestmentCurrentValueController,
          selectedInvestmentIndex: selectedInvestmentIndex,
          showChangeNameDialog: _showChangeNameDialog,
          updateInvestmentType: updateInvestmentType,
          interestBeforeEnd: interestBeforeEnd,
          updateInvestmentStart: updateInvestmentStart,
          updateInvestmentEnd: updateInvestmentEnd,
          addOrUpdate: () {
            final investment = Investment(
              _updateInvestmentNameController!.text,
              updateInvestmentType == 0 ? "fixed" : "fluctuate",
              updateInvestmentType == 0
                  ? 0
                  : double.parse(
                      _updateInvestmentCurrentValueController?.text ?? "0"),
              updateInvestmentType == 0 && interestBeforeEnd,
              updateInvestmentType == 0
                  ? double.parse(_updateInvestmentRateController?.text ?? "0") /
                      100
                  : 0,
              updateInvestmentType == 0
                  ? formatDate(updateInvestmentStart)
                  : "",
              updateInvestmentType == 0 && updateInvestmentEnd != null
                  ? formatDate(updateInvestmentEnd!)
                  : "",
            );
            if (selectedInvestmentIndex == null) {
              widget.investments.add(investment);
            } else {
              widget.investments[selectedInvestmentIndex!] = investment;
            }
            widget.refresh();
            _onUpdateSelectInvestmentName(
                _updateInvestmentNameController?.text);
            setState(() {});
          },
          deleteInvestment: () {
            widget.investments.removeAt(selectedInvestmentIndex!);
            widget.refresh();
            setState(() {});
          },
          onChangeInvestmentType: (value) {
            setState(() {
              updateInvestmentType = value as int;
            });
          },
          onChangeInterestBeforeEnd: (value) {
            setState(() {
              interestBeforeEnd = value ?? false;
            });
          },
          onChangeInvestmentStart: () async {
            updateInvestmentStart = await showDatePicker(
                    context: context,
                    initialDate: updateInvestmentStart,
                    firstDate: DateTime(1970, 1, 1),
                    lastDate: DateTime(9999, 12, 31)) ??
                updateInvestmentStart;
            setState(() {});
          },
          onChangeInvestmentEnd: () async {
            updateInvestmentEnd = await showDatePicker(
                    context: context,
                    initialDate: updateInvestmentEnd ?? updateInvestmentStart,
                    firstDate: updateInvestmentStart,
                    lastDate: DateTime(9999, 12, 31)) ??
                updateInvestmentEnd;
            setState(() {});
          },
          onClearInvestmentEnd: () {
            updateInvestmentEnd = null;
            setState(() {});
          },
        ),
        Expanded(child: _buildInvestmentRightSide()),
      ],
    ));
  }

  void _onUpdateSelectInvestmentName(String? text) {
    selectedInvestmentIndex = null;
    for (int i = 0; i < widget.investments.length; i++) {
      if (widget.investments[i].name == text) {
        selectedInvestmentIndex = i;
        if (widget.investments[i].type == "fixed") {
          investmentShowPageType = 0;
        } else {
          investmentShowPageType = 1;
        }
        break;
      }
    }
    setState(() {});
  }

  String? _changeNameErrorText;

  void _showChangeNameDialog() {
    _newInvestmentNameController?.text =
        _updateInvestmentNameController?.text ?? "";
    showDialog(
        context: context,
        builder: (_) {
          return StatefulBuilder(builder: (context, setState) {
            final clearErrorText = () {
              _changeNameErrorText = null;
              setState(() {});
            };
            _newInvestmentNameController?.addListener(clearErrorText);
            return AlertDialog(
                title: Text("New Name"),
                content: TextField(
                    controller: _newInvestmentNameController,
                    decoration:
                        InputDecoration(errorText: _changeNameErrorText)),
                actions: [
                  TextButton(
                      child: Text("OK"),
                      onPressed: (_newInvestmentNameController?.text ?? "")
                              .trim()
                              .isNotEmpty
                          ? () {
                              final newName =
                                  _newInvestmentNameController?.text.trim();
                              for (int i = 0;
                                  i < widget.investments.length;
                                  i++) {
                                if (widget.investments[i].name == newName) {
                                  _changeNameErrorText = "Name already exists";
                                  setState(() {});
                                  return;
                                }
                              }
                              widget.investments[selectedInvestmentIndex!]
                                  .name = newName!;
                              _updateInvestmentNameController?.text = newName;
                              widget.refresh();
                              _newInvestmentNameController
                                  ?.removeListener(clearErrorText);
                              Navigator.of(context).pop();
                            }
                          : null),
                  TextButton(
                      child: Text("Cancel"),
                      onPressed: () {
                        _newInvestmentNameController
                            ?.removeListener(clearErrorText);
                        Navigator.of(context).pop();
                      }),
                ]);
          });
        });
  }

  List<int> _getFixedInvestmentCurrentPage() {
    return widget.filteredFixedInvestment.sublist(
        fixedInvestmentPageIndex * widget.pageSize,
        min((fixedInvestmentPageIndex + 1) * widget.pageSize,
            widget.filteredFixedInvestment.length));
  }

  List<int> _getFluctuateInvestmentCurrentPage() {
    return widget.filteredFluctuateInvestment.sublist(
        fluctuateInvestmentPageIndex * widget.pageSize,
        min((fluctuateInvestmentPageIndex + 1) * widget.pageSize,
            widget.filteredFluctuateInvestment.length));
  }

  Widget _buildInvestmentRightSide() {
    return Container(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(child: _buildInvestmentButtonBar()),
                  investmentShowPageType == 0
                      ? _buildFixedInvestmentPageController()
                      : _buildFluctuateInvestmentPageController()
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: investmentShowPageType == 0
                        ? _buildFixedInvestmentDataTable()
                        : _buildFluctuateInvestmentDataTable(),
                  )),
            ),
          ],
        ));
  }

  Widget _buildInvestmentButtonBar() {
    return Wrap(
      spacing: 4.0,
      children: [
        OutlinedButton(
          child: Text("Fixed"),
          onPressed: investmentShowPageType != 0
              ? () {
                  setState(() {
                    investmentShowPageType = 0;
                  });
                }
              : null,
        ),
        OutlinedButton(
          child: Text("Fluctuate"),
          onPressed: investmentShowPageType != 1
              ? () {
                  setState(() {
                    investmentShowPageType = 1;
                  });
                }
              : null,
        ),
        Checkbox(value: widget.showEmpty, onChanged: widget.changeShowEmpty),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
          child: Text("Show Empty"),
        ),
        Checkbox(
            value: widget.showExpired, onChanged: widget.changeShowExpired),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
          child: Text("Show Expired"),
        ),
      ],
    );
  }

  Widget _buildFixedInvestmentPageController() {
    return Row(children: [
      Container(
          width: 24,
          height: 24,
          child: IconButton(
              iconSize: 20,
              icon: Icon(Icons.chevron_left),
              onPressed: fixedInvestmentPageIndex > 0
                  ? () {
                      setState(() {
                        fixedInvestmentPageIndex =
                            max(fixedInvestmentPageIndex - 1, 0);
                      });
                    }
                  : null)),
      Container(
          padding: EdgeInsets.only(top: 8.0, left: 12.0),
          child: Text(
              "${fixedInvestmentPageIndex + 1} / ${maxFixedInvestmentPageIndex + 1}")),
      Container(
          width: 24,
          height: 24,
          child: IconButton(
              iconSize: 20,
              icon: Icon(Icons.chevron_right),
              onPressed: fixedInvestmentPageIndex < maxFixedInvestmentPageIndex
                  ? () {
                      setState(() {
                        fixedInvestmentPageIndex = min(
                            fixedInvestmentPageIndex + 1,
                            maxFixedInvestmentPageIndex);
                      });
                    }
                  : null)),
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextButton(
            child: Text("Go To"),
            onPressed: () {
              int value =
                  int.parse(_jumpToFixedInvestmentPageController?.text ?? "1") -
                      1;
              if (value < 0) value = 0;
              if (value > maxFixedInvestmentPageIndex)
                value = maxFixedInvestmentPageIndex;
              setState(() {
                fixedInvestmentPageIndex = value;
              });
            }),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Container(
            width: 50,
            padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: TextField(
                controller: _jumpToFixedInvestmentPageController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                ],
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    isCollapsed: true,
                    contentPadding: EdgeInsets.all(4.0)))),
      )
    ]);
  }

  Widget _buildFluctuateInvestmentPageController() {
    return Row(children: [
      Container(
          width: 24,
          height: 24,
          child: IconButton(
              iconSize: 20,
              icon: Icon(Icons.chevron_left),
              onPressed: fluctuateInvestmentPageIndex > 0
                  ? () {
                      setState(() {
                        fluctuateInvestmentPageIndex =
                            max(fluctuateInvestmentPageIndex - 1, 0);
                      });
                    }
                  : null)),
      Container(
          padding: EdgeInsets.only(top: 8.0, left: 12.0),
          child: Text(
              "${fluctuateInvestmentPageIndex + 1} / ${maxFluctuateInvestmentPageIndex + 1}")),
      Container(
          width: 24,
          height: 24,
          child: IconButton(
              iconSize: 20,
              icon: Icon(Icons.chevron_right),
              onPressed:
                  fluctuateInvestmentPageIndex < maxFluctuateInvestmentPageIndex
                      ? () {
                          setState(() {
                            fluctuateInvestmentPageIndex = min(
                                fluctuateInvestmentPageIndex + 1,
                                maxFluctuateInvestmentPageIndex);
                          });
                        }
                      : null)),
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextButton(
            child: Text("Go To"),
            onPressed: () {
              int value = int.parse(
                      _jumpToFluctuateInvestmentPageController?.text ?? "1") -
                  1;
              if (value < 0) value = 0;
              if (value > maxFluctuateInvestmentPageIndex)
                value = maxFluctuateInvestmentPageIndex;
              setState(() {
                fluctuateInvestmentPageIndex = value;
              });
            }),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Container(
            width: 50,
            padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: TextField(
                controller: _jumpToFluctuateInvestmentPageController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                ],
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    isCollapsed: true,
                    contentPadding: EdgeInsets.all(4.0)))),
      )
    ]);
  }

  Widget _buildFixedInvestmentDataTable() {
    return DataTable(
        columnSpacing: 10.0,
        horizontalMargin: 2.0,
        headingRowHeight: 25.0,
        sortColumnIndex: widget.sortFixedInvestmentColumn,
        sortAscending: widget.sortFixedInvestmentAscending,
        columns: [
          DataColumn(
              onSort: widget.onSortFixedTable,
              label: Column(
                children: [
                  Text("Name"),
                ],
              )),
          DataColumn(
              onSort: widget.onSortFixedTable,
              label: Column(
                children: [
                  Text("Invested"),
                ],
              )),
          DataColumn(
              onSort: widget.onSortFixedTable,
              label: Column(
                children: [
                  Text("Start"),
                ],
              )),
          DataColumn(
              onSort: widget.onSortFixedTable,
              label: Column(
                children: [
                  Text("End"),
                ],
              )),
          DataColumn(
              onSort: widget.onSortFixedTable,
              label: Column(
                children: [
                  Text("Period"),
                ],
              )),
          DataColumn(
              onSort: widget.onSortFixedTable,
              label: Column(
                children: [
                  Text("Rate"),
                ],
              )),
          DataColumn(
              label: Column(
            children: [
              Text("Profit/Year"),
            ],
          )),
          DataColumn(
              label: Column(
            children: [
              Text("Total Profit"),
            ],
          )),
        ],
        rows: List.generate(widget.pageSize, (index) {
          final currentFixedInvestmentPage = _getFixedInvestmentCurrentPage();
          if (index < widget.pageSize &&
              index < currentFixedInvestmentPage.length) {
            final investmentIndex = currentFixedInvestmentPage[index];
            final investment = widget.fixedInvestments[investmentIndex];
            return DataRow(
                selected: investment.index == selectedInvestmentIndex,
                cells: [
                  DataCell(
                      // Name
                      Container(
                          width: 150,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(investment.name),
                          )), onTap: () {
                    _updateInvestmentNameController?.text = investment.name;
                    updateInvestmentType = 0;
                    interestBeforeEnd = investment.interestBeforeEnd;
                    updateInvestmentStart = investment.startDate;
                    updateInvestmentEnd = investment.endDate;
                    _updateInvestmentRateController?.text =
                        (investment.rate * 100).toStringAsFixed(2);
                    _onUpdateSelectInvestmentName(
                        _updateInvestmentNameController?.text);
                  }),
                  DataCell(
                      // Invested
                      Container(
                    width: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                          (investment.investedAmount / 100).toStringAsFixed(2)),
                    ),
                  )),
                  DataCell(// Start
                      Container(
                    width: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(formatDate(investment.startDate)),
                    ),
                  )),
                  DataCell(// End
                      Container(
                    width: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        investment.hasEndDate
                            ? formatDate(investment.endDate!)
                            : "",
                        style: TextStyle(
                            color:
                                investment.expired ? Colors.red : Colors.black),
                      ),
                    ),
                  )),
                  DataCell(// Period
                      Container(
                    width: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(investment.periodStr ?? ""),
                    ),
                  )),
                  DataCell(// Rate
                      Container(
                          width: 60,
                          child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                  "${(investment.rate * 100).toStringAsFixed(2)}%")))),
                  DataCell(Container(
                      // Interest Per Year
                      width: 100,
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text((investment.interestPerYear / 100)
                              .toStringAsFixed(2))))),
                  DataCell(// Expected Total Interest
                      Container(
                    width: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(investment.hasEndDate
                          ? (investment.totalProfit! / 100).toStringAsFixed(2)
                          : ""),
                    ),
                  )),
                ]);
          }
          return DataRow(cells: [
            DataCell(Container(width: 150)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 60)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
          ]);
        }));
  }

  Widget _buildFluctuateInvestmentDataTable() {
    return DataTable(
        columnSpacing: 10.0,
        horizontalMargin: 2.0,
        headingRowHeight: 25.0,
        sortColumnIndex: widget.sortFluctuateInvestmentColumn,
        sortAscending: widget.sortFluctuateInvestmentAscending,
        columns: [
          DataColumn(
              onSort: widget.onSortFluctuateTable,
              label: Column(
                children: [
                  Text("Name"),
                ],
              )),
          DataColumn(
              onSort: widget.onSortFluctuateTable,
              label: Column(
                children: [
                  Text("Invested"),
                ],
              )),
          DataColumn(
              onSort: widget.onSortFluctuateTable,
              label: Column(
                children: [
                  Text("Current Value"),
                ],
              )),
          DataColumn(
              label: Column(
            children: [
              Text("Profit"),
            ],
          )),
          DataColumn(
              label: Column(
            children: [
              Text("Profit Rate"),
            ],
          )),
        ],
        rows: List.generate(widget.pageSize, (index) {
          final currentFluctuateInvestmentPage =
              _getFluctuateInvestmentCurrentPage();
          if (index < widget.pageSize &&
              index < currentFluctuateInvestmentPage.length) {
            final investmentIndex = currentFluctuateInvestmentPage[index];
            final investment = widget.fluctuateInvestments[investmentIndex];
            return DataRow(
                selected: investment.index == selectedInvestmentIndex,
                cells: [
                  DataCell(
                      // Name
                      Container(
                          width: 200,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(investment.name),
                          )), onTap: () {
                    _updateInvestmentNameController?.text = investment.name;
                    updateInvestmentType = 1;
                    _updateInvestmentCurrentValueController?.text =
                        (investment.currentAmount / 100).toStringAsFixed(2);
                    _onUpdateSelectInvestmentName(
                        _updateInvestmentNameController?.text);
                  }),
                  DataCell(
                    // Invested
                    Container(
                      width: 100,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text((investment.investedAmount / 100)
                            .toStringAsFixed(2)),
                      ),
                    ),
                  ),
                  DataCell(// Current Value
                      Container(
                    width: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                          (investment.currentAmount / 100).toStringAsFixed(2)),
                    ),
                  )),
                  DataCell(// Profit
                      Container(
                    width: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text((investment.profit / 100).toStringAsFixed(2)),
                    ),
                  )),
                  DataCell(// Profit Rate
                      Container(
                    width: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                          "${(investment.profitRate * 100).toStringAsFixed(2)}%"),
                    ),
                  )),
                ]);
          }
          return DataRow(cells: [
            DataCell(Container(width: 200)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
          ]);
        }));
  }
}

class _InvestmentLeftSide extends StatefulWidget {
  final TextEditingController? selectNameController;
  final TextEditingController? updateInvestmentRateController;
  final TextEditingController? updateCurrentValueController;
  final int? selectedInvestmentIndex;
  final int updateInvestmentType;
  final bool interestBeforeEnd;
  final DateTime updateInvestmentStart;
  final DateTime? updateInvestmentEnd;
  final VoidCallback showChangeNameDialog;
  final VoidCallback addOrUpdate;
  final VoidCallback deleteInvestment;
  final void Function(int? investmentType) onChangeInvestmentType;
  final void Function(bool? interestBeforeEnd) onChangeInterestBeforeEnd;
  final VoidCallback onChangeInvestmentStart;
  final VoidCallback onChangeInvestmentEnd;
  final VoidCallback onClearInvestmentEnd;
  _InvestmentLeftSide(
      {Key? key,
      this.selectNameController,
      this.updateInvestmentRateController,
      this.updateCurrentValueController,
      this.selectedInvestmentIndex,
      required this.showChangeNameDialog,
      required this.updateInvestmentType,
      required this.interestBeforeEnd,
      required this.updateInvestmentStart,
      required this.updateInvestmentEnd,
      required this.addOrUpdate,
      required this.deleteInvestment,
      required this.onChangeInvestmentType,
      required this.onChangeInterestBeforeEnd,
      required this.onChangeInvestmentStart,
      required this.onChangeInvestmentEnd,
      required this.onClearInvestmentEnd})
      : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _InvestmentLeftSideState();
  }
}

class _InvestmentLeftSideState extends State<_InvestmentLeftSide> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width / 6,
        child: Column(mainAxisSize: MainAxisSize.max, children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: _buildInvestmentLeftSideTop(),
          ),
          Expanded(
              child: Container(
                  padding: EdgeInsets.all(4.0),
                  child: _buildInvestmentUpdate()))
        ]));
  }

  Widget _buildInvestmentLeftSideTop() {
    return Row(children: [
      OutlinedButton(
          onPressed: widget.selectNameController?.text.trim().isEmpty ?? true
              ? null
              : widget.addOrUpdate,
          child: Text(
              (widget.selectedInvestmentIndex == null) ? "Add" : "Update")),
      Expanded(child: Container()),
      Expanded(child: Container()),
      OutlinedButton(
          onPressed: widget.selectedInvestmentIndex == null
              ? null
              : widget.deleteInvestment,
          child: Text("Delete",
              style: TextStyle(
                  color: widget.selectedInvestmentIndex == null
                      ? Colors.red[10]
                      : Colors.red))),
    ]);
  }

  Widget _buildInvestmentUpdate() {
    return Container(
        child: Column(
      children: [
        Row(
          children: [
            Expanded(
                child: TextField(
                    controller: widget.selectNameController,
                    decoration: InputDecoration(
                        hintText: "Name",
                        isCollapsed: true,
                        contentPadding: EdgeInsets.all(8.0),
                        border: OutlineInputBorder()))),
            OutlinedButton(
                onPressed: widget.selectedInvestmentIndex == null
                    ? null
                    : widget.showChangeNameDialog,
                child: Text("Change")),
          ],
        ),
        Row(
          children: [
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton(
                isExpanded: true,
                isDense: true,
                value: widget.updateInvestmentType,
                items: [
                  DropdownMenuItem(child: Text("Fixed"), value: 0),
                  DropdownMenuItem(child: Text("Fluctuate"), value: 1),
                ],
                onChanged: widget.onChangeInvestmentType,
              ),
            )),
          ],
        ),
        widget.updateInvestmentType == 0
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Checkbox(
                        value: widget.interestBeforeEnd,
                        onChanged: widget.onChangeInterestBeforeEnd),
                    Expanded(child: Text("Interest Before End"))
                  ],
                ),
              )
            : Container(),
        widget.updateInvestmentType == 0
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [
                  Container(width: 35, child: Text("Start")),
                  TextButton(
                      child: Text(formatDate(widget.updateInvestmentStart)),
                      onPressed: widget.onChangeInvestmentStart)
                ]),
              )
            : Container(),
        widget.updateInvestmentType == 0
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [
                  Container(width: 35, child: Text("End")),
                  TextButton(
                      child: Text(widget.updateInvestmentEnd == null
                          ? "Unspecified"
                          : formatDate(widget.updateInvestmentEnd!)),
                      onPressed: widget.onChangeInvestmentEnd),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: OutlinedButton(
                        onPressed: widget.onClearInvestmentEnd,
                        child: Text("Clear")),
                  )
                ]),
              )
            : Container(),
        widget.updateInvestmentType == 0
            ? Row(children: [
                Expanded(
                    child: TextField(
                        controller: widget.updateInvestmentRateController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d{0,2}(\.\d{0,2})?'))
                        ],
                        decoration: InputDecoration(
                            hintText: "Rate",
                            isCollapsed: true,
                            contentPadding: EdgeInsets.all(8.0),
                            border: OutlineInputBorder()))),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text("%"),
                )
              ])
            : Container(),
        widget.updateInvestmentType == 1
            ? Row(children: [
                Expanded(
                    child: TextField(
                        controller: widget.updateCurrentValueController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+(\.\d{0,2})?'))
                        ],
                        decoration: InputDecoration(
                            hintText: "Current Value",
                            isCollapsed: true,
                            contentPadding: EdgeInsets.all(8.0),
                            border: OutlineInputBorder()))),
              ])
            : Container(),
      ],
    ));
  }
}
