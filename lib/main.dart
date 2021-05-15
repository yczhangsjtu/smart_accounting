import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_accounting/utils.dart';
import 'storage.dart';
import 'data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Accounting',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Main(title: 'Smart Accounting'),
    );
  }
}

class Main extends StatefulWidget {
  Main({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  AccountData? _accountData;
  AnalyzedAccountData? _analyzedAccountData;
  Set<int> selected = {};
  List<int> filtered = [];
  int pageIndex = 0;
  List<int> currentPage = [];
  List<Filter> filters = [];
  final int pageSize = 15;
  int leftSideSelector = 0;

  TextEditingController? _jumpToPageController;
  TextEditingController? _filterAllController;
  TextEditingController? _filterTimeController;
  TextEditingController? _filterFromAccountController;
  TextEditingController? _filterFromAmountController;
  TextEditingController? _filterToAccountController;
  TextEditingController? _filterToAmountController;
  TextEditingController? _filterCategoryController;
  TextEditingController? _filterSubcategoryController;
  TextEditingController? _filterCommentController;
  TextEditingController? _filterResetController;
  bool filterAllPrecise = false;
  bool filterTimePrecise = false;
  bool filterFromAccountPrecise = false;
  bool filterFromAmountPrecise = false;
  bool filterToAccountPrecise = false;
  bool filterToAmountPrecise = false;
  bool filterCategoryPrecise = false;
  bool filterSubcategoryPrecise = false;
  bool filterCommentPrecise = false;
  bool filterResetPrecise = false;
  int filterTransactionType = -1;

  @override
  void initState() {
    super.initState();
    _jumpToPageController = TextEditingController();
    _filterAllController = TextEditingController();
    _filterTimeController = TextEditingController();
    _filterFromAccountController = TextEditingController();
    _filterFromAmountController = TextEditingController();
    _filterToAccountController = TextEditingController();
    _filterToAmountController = TextEditingController();
    _filterCategoryController = TextEditingController();
    _filterSubcategoryController = TextEditingController();
    _filterCommentController = TextEditingController();
    _filterResetController = TextEditingController();
    _filterAllController?.addListener(_filterChangeListener);
    _filterTimeController?.addListener(_filterChangeListener);
    _filterFromAccountController?.addListener(_filterChangeListener);
    _filterFromAmountController?.addListener(_filterChangeListener);
    _filterToAccountController?.addListener(_filterChangeListener);
    _filterToAmountController?.addListener(_filterChangeListener);
    _filterCategoryController?.addListener(_filterChangeListener);
    _filterSubcategoryController?.addListener(_filterChangeListener);
    _filterCommentController?.addListener(_filterChangeListener);
    _filterResetController?.addListener(_filterChangeListener);
  }

  void _filterChangeListener() {
    filters = [];
    if (_filterAllController?.text.isNotEmpty ?? false) {
      filters.add(Filter(
          Field.All, _filterAllController?.text ?? "", filterAllPrecise));
    }
    if (_filterTimeController?.text.isNotEmpty ?? false) {
      filters.add(Filter(
          Field.Time, _filterTimeController?.text ?? "", filterTimePrecise));
    }
    if (_filterFromAccountController?.text.isNotEmpty ?? false) {
      filters.add(Filter(Field.OutAccount,
          _filterFromAccountController?.text ?? "", filterFromAccountPrecise));
    }
    if (_filterFromAmountController?.text.isNotEmpty ?? false) {
      filters.add(Filter(Field.OutAmount,
          _filterFromAmountController?.text ?? "", filterFromAmountPrecise));
    }
    if (_filterToAccountController?.text.isNotEmpty ?? false) {
      filters.add(Filter(Field.InAccount,
          _filterToAccountController?.text ?? "", filterToAccountPrecise));
    }
    if (_filterToAmountController?.text.isNotEmpty ?? false) {
      filters.add(Filter(Field.InAmount, _filterToAmountController?.text ?? "",
          filterToAmountPrecise));
    }
    if (filterTransactionType != -1) {
      filters.add(Filter(
          Field.Type, transactionTypeToString(filterTransactionType), true));
    }
    if (_filterCategoryController?.text.isNotEmpty ?? false) {
      filters.add(Filter(Field.Category, _filterCategoryController?.text ?? "",
          filterCategoryPrecise));
    }
    if (_filterSubcategoryController?.text.isNotEmpty ?? false) {
      filters.add(Filter(Field.Subcategory,
          _filterSubcategoryController?.text ?? "", filterSubcategoryPrecise));
    }
    if (_filterCommentController?.text.isNotEmpty ?? false) {
      filters.add(Filter(Field.Comment, _filterCommentController?.text ?? "",
          filterCommentPrecise));
    }
    if (_filterResetController?.text.isNotEmpty ?? false) {
      filters.add(Filter(Field.ResetTo, _filterResetController?.text ?? "",
          filterResetPrecise));
    }
    print(filters);
    setState(() {
      _updateFiltered();
    });
  }

  @override
  void dispose() {
    _jumpToPageController?.dispose();
    _filterAllController?.dispose();
    _filterTimeController?.dispose();
    _filterFromAccountController?.dispose();
    _filterFromAmountController?.dispose();
    _filterToAccountController?.dispose();
    _filterToAmountController?.dispose();
    _filterCategoryController?.dispose();
    _filterSubcategoryController?.dispose();
    _filterCommentController?.dispose();
    _filterResetController?.dispose();
    super.dispose();
  }

  int get maxPageIndex {
    return (filtered.length - 1) ~/ pageSize;
  }

  void _updateFiltered() {
    filtered = filter(filters, _accountData?.transactions);
    selected = {};
    if (pageIndex > maxPageIndex) {
      pageIndex = maxPageIndex;
    }
    _updateCurrentPage();
  }

  void _updateCurrentPage() {
    currentPage = filtered.sublist(
        pageIndex * pageSize, min((pageIndex + 1) * pageSize, filtered.length));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: _buildTitleBar()),
        body: TabBarView(
          children: [
            Container(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildLeftSide(),
                  Expanded(child: _buildRightSide())
                ],
              ),
            ),
            Container(color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 300,
          child: TabBar(
            tabs: [
              Tab(icon: Text("Transactions")),
              Tab(icon: Text("Investments")),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildOpenButton(),
          ),
        )
      ],
    );
  }

  Widget _buildOpenButton() {
    return OutlinedButton(
        onPressed: () async {
          _accountData = await readAccountData();
          _analyzedAccountData = analyze(_accountData);
          reverseSortTransactions(_accountData?.transactions);
          _updateFiltered();
          setState(() {});
        },
        child: Text("Open",
            style: TextStyle(
              color: Colors.black,
            )));
  }

  Widget _buildLeftSide() {
    return Column(mainAxisSize: MainAxisSize.max, children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildLeftSideTop(),
      ),
      Expanded(
          child: Container(
              width: MediaQuery.of(context).size.width / 6,
              padding: EdgeInsets.all(8.0),
              child: leftSideSelector == 0
                  ? _buildAccountList()
                  : leftSideSelector == 1
                      ? _buildFilter()
                      : Container()))
    ]);
  }

  Widget _buildLeftSideTop() {
    return Row(children: [
      OutlinedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateColor.resolveWith(
                (states) => leftSideSelector == 0 ? Colors.blue : Colors.white),
            foregroundColor: MaterialStateColor.resolveWith(
                (states) => leftSideSelector == 0 ? Colors.white : Colors.blue),
          ),
          onPressed: () {
            setState(() {
              leftSideSelector = 0;
            });
          },
          child: Text("Account")),
      OutlinedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateColor.resolveWith(
                (states) => leftSideSelector == 1 ? Colors.blue : Colors.white),
            foregroundColor: MaterialStateColor.resolveWith(
                (states) => leftSideSelector == 1 ? Colors.white : Colors.blue),
          ),
          onPressed: () {
            setState(() {
              leftSideSelector = 1;
            });
          },
          child: Text("Filter")),
      OutlinedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateColor.resolveWith(
                (states) => leftSideSelector == 2 ? Colors.blue : Colors.white),
            foregroundColor: MaterialStateColor.resolveWith(
                (states) => leftSideSelector == 2 ? Colors.white : Colors.blue),
          ),
          onPressed: () {
            setState(() {
              leftSideSelector = 2;
            });
          },
          child: Text("Update")),
    ]);
  }

  Widget _buildAccountList() {
    return ListView.builder(
        itemCount: _analyzedAccountData?.accounts.length ?? 0,
        itemBuilder: (context, index) {
          final account = _analyzedAccountData?.accounts[index];
          return _AccountCard(account?.name ?? "", account?.balance ?? 0);
        });
  }

  Widget _buildSingleFilter(String hint, TextEditingController? controller,
      bool value, void Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Container(
              padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                      hintText: hint,
                      border: OutlineInputBorder(),
                      isCollapsed: true,
                      contentPadding: EdgeInsets.all(4.0)))),
        ),
        Checkbox(
            value: value,
            onChanged: (changedValue) {
              setState(() {
                onChanged(changedValue ?? false);
                _filterChangeListener();
              });
            }),
      ],
    );
  }

  Widget _buildFilter() {
    return ListView(
      children: [
        _buildSingleFilter("Filter All", _filterAllController, filterAllPrecise,
            (value) {
          filterAllPrecise = value;
        }),
        _buildSingleFilter(
            "Filter Time", _filterTimeController, filterTimePrecise, (value) {
          filterTimePrecise = value;
        }),
        _buildSingleFilter("Filter From Account", _filterFromAccountController,
            filterFromAccountPrecise, (value) {
          filterFromAccountPrecise = value;
        }),
        _buildSingleFilter("Filter From Amount", _filterFromAmountController,
            filterFromAmountPrecise, (value) {
          filterFromAmountPrecise = value;
        }),
        _buildSingleFilter("Filter To Account", _filterToAccountController,
            filterToAccountPrecise, (value) {
          filterToAccountPrecise = value;
        }),
        _buildSingleFilter("Filter To Amount", _filterToAmountController,
            filterToAmountPrecise, (value) {
          filterToAmountPrecise = value;
        }),
        DropdownButton(
            value: filterTransactionType,
            items: [
              DropdownMenuItem(child: Text("Transaction Type"), value: -1),
              DropdownMenuItem(child: Text("Payment"), value: 0),
              DropdownMenuItem(child: Text("Receive"), value: 1),
              DropdownMenuItem(child: Text("Transfer"), value: 2),
              DropdownMenuItem(child: Text("Reset"), value: 3),
            ],
            onChanged: (value) {
              filterTransactionType = value as int? ?? 0;
              _filterChangeListener();
            }),
        _buildSingleFilter(
            "Filter Category", _filterCategoryController, filterCategoryPrecise,
            (value) {
          filterCategoryPrecise = value;
        }),
        _buildSingleFilter("Filter Subcategory", _filterSubcategoryController,
            filterSubcategoryPrecise, (value) {
          filterSubcategoryPrecise = value;
        }),
        _buildSingleFilter(
            "Filter Comment", _filterCommentController, filterCommentPrecise,
            (value) {
          filterCommentPrecise = value;
        }),
        _buildSingleFilter(
            "Filter Reset", _filterResetController, filterResetPrecise,
            (value) {
          filterResetPrecise = value;
        }),
        TextButton(
            child: Text("Clear"),
            onPressed: () {
              _filterAllController?.text = "";
              _filterTimeController?.text = "";
              _filterFromAccountController?.text = "";
              _filterFromAmountController?.text = "";
              _filterToAccountController?.text = "";
              _filterToAmountController?.text = "";
              filterTransactionType = -1;
              _filterCategoryController?.text = "";
              _filterSubcategoryController?.text = "";
              _filterCommentController?.text = "";
              _filterResetController?.text = "";
              _filterChangeListener();
            })
      ],
    );
  }

  Widget _buildRightSide() {
    return Container(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(child: _buildButtonBar()),
                  _buildPageController(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: _buildDataTable(),
                  )),
            ),
          ],
        ));
  }

  Widget _buildButtonBar() {
    return Wrap(
      spacing: 4.0,
      children: [
        OutlinedButton(
          child: Text("New"),
          onPressed: () {
            print("New");
          },
        ),
        OutlinedButton(
          child: Text("Select All"),
          onPressed: () {
            setState(() {
              selected = Set.from(filtered);
            });
          },
        ),
        OutlinedButton(
          child: Text("Select Page"),
          onPressed: () {
            setState(() {
              selected = Set.from(currentPage);
            });
          },
        ),
        OutlinedButton(
          child: Text("Unselect All"),
          onPressed: () {
            setState(() {
              selected = {};
            });
          },
        ),
        OutlinedButton(
          child: Text("Import Alipay"),
          onPressed: () {
            print("Import Alipay");
          },
        ),
        OutlinedButton(
          child: Text("Import Wechat"),
          onPressed: () {
            print("Import Wechat");
          },
        ),
      ],
    );
  }

  Widget _buildPageController() {
    return Row(children: [
      Container(
          width: 24,
          height: 24,
          child: IconButton(
              iconSize: 20,
              icon: Icon(Icons.chevron_left),
              onPressed: pageIndex > 0
                  ? () {
                      setState(() {
                        pageIndex = max(pageIndex - 1, 0);
                        _updateCurrentPage();
                      });
                    }
                  : null)),
      Container(
          padding: EdgeInsets.only(top: 8.0, left: 12.0),
          child: Text("${pageIndex + 1} / ${maxPageIndex + 1}")),
      Container(
          width: 24,
          height: 24,
          child: IconButton(
              iconSize: 20,
              icon: Icon(Icons.chevron_right),
              onPressed: pageIndex < maxPageIndex
                  ? () {
                      setState(() {
                        pageIndex = min(pageIndex + 1, maxPageIndex);
                        _updateCurrentPage();
                      });
                    }
                  : null)),
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextButton(
            child: Text("Go To"),
            onPressed: () {
              int value = int.parse(_jumpToPageController?.text ?? "1") - 1;
              if (value < 0) value = 0;
              if (value > maxPageIndex) value = maxPageIndex;
              setState(() {
                pageIndex = value;
                _updateCurrentPage();
              });
            }),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Container(
            width: 50,
            padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: TextField(
                controller: _jumpToPageController,
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

  Widget _buildDataTable() {
    return DataTable(
        columnSpacing: 10.0,
        horizontalMargin: 2.0,
        headingRowHeight: 25.0,
        columns: [
          DataColumn(
              label: Column(
            children: [
              Container(
                  width: 30,
                  child: Center(child: Text(this.selected.length.toString()))),
            ],
          )),
          DataColumn(
              label: Column(
            children: [
              Text("Time"),
            ],
          )),
          DataColumn(
              label: Column(
            children: [
              Text("From"),
            ],
          )),
          DataColumn(
              label: Column(
            children: [
              Text("To"),
            ],
          )),
          DataColumn(
              label: Column(
            children: [
              Text("Type"),
            ],
          )),
          DataColumn(
              label: Column(
            children: [
              Text("Category"),
            ],
          )),
          DataColumn(
              label: Column(
            children: [
              Text("Subcategory"),
            ],
          )),
          DataColumn(
              label: Column(
            children: [
              Text("Comment"),
            ],
          )),
          DataColumn(
              label: Column(
            children: [
              Text("Reset"),
            ],
          )),
        ],
        rows: List.generate(pageSize, (index) {
          if (index < pageSize && index < currentPage.length) {
            final transactionIndex = currentPage[index];
            final transaction = _accountData?.transactions[transactionIndex];
            if (transaction != null)
              return DataRow(cells: [
                DataCell(Container(
                  width: 30,
                  child: Center(
                    child: Checkbox(
                      onChanged: (value) {
                        if (value ?? false) {
                          selected.add(transactionIndex);
                        } else {
                          selected.remove(transactionIndex);
                        }
                        setState(() {});
                      },
                      value: selected.contains(transactionIndex),
                    ),
                  ),
                )),
                DataCell(Container(
                  width: 100,
                  child: Column(
                    children: [
                      Text(transaction.time.substring(0, 10)),
                      Text(transaction.time.substring(11)),
                    ],
                  ),
                )),
                DataCell(Container(
                  width: 100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [
                        Text(transaction.outAccount),
                        transaction.entryType == 0 || transaction.entryType == 2
                            ? Text(processMoney(transaction.outAmount),
                                style: TextStyle(color: Colors.red))
                            : Container(),
                      ],
                    ),
                  ),
                )),
                DataCell(Container(
                  width: 100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [
                        Text(transaction.inAccount),
                        transaction.entryType == 1 || transaction.entryType == 2
                            ? Text(processMoney(transaction.inAmount),
                                style: TextStyle(color: Colors.green))
                            : Container(),
                      ],
                    ),
                  ),
                )),
                DataCell(Container(
                    width: 100,
                    child:
                        Text(transactionTypeToString(transaction.entryType)))),
                DataCell(Container(
                    width: 100,
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(transaction.category)))),
                DataCell(Container(
                    width: 100,
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(transaction.subcategory)))),
                DataCell(Container(
                    width: 300,
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(transaction.comment)))),
                DataCell(Container(
                  width: 100,
                  child: Text(transaction.entryType == 3
                      ? processMoney(transaction.resetTo)
                      : ""),
                )),
              ]);
          }
          return DataRow(cells: [
            DataCell(Container(width: 30)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 100)),
            DataCell(Container(width: 300)),
            DataCell(Container(width: 100)),
          ]);
        }));
  }
}

class _AccountCard extends StatelessWidget {
  final String name;
  final int balance;

  _AccountCard(this.name, this.balance);

  @override
  Widget build(BuildContext context) {
    return Card(
        color: Colors.green[500],
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(this.name, style: TextStyle(color: Colors.white)),
                ],
              ),
              Row(
                children: [
                  Text(processMoney(this.balance),
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ));
  }
}