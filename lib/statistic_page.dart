import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_accounting/data.dart';
import 'package:smart_accounting/utils.dart';

class StatisticData {
  final List<CategoryValue> categoryPaymentSums;
  final List<CategorySubcategoryValues> subcategoryPaymentSums;
  final List<CategoryValue> categoryReceiveSums;
  final List<CategorySubcategoryValues> subcategoryReceiveSums;
  StatisticData(
    this.categoryPaymentSums,
    this.subcategoryPaymentSums,
    this.categoryReceiveSums,
    this.subcategoryReceiveSums,
  );
}

StatisticData? statisticalAnalyze(
    AccountData? accountData,
    AnalyzedAccountData? analyzedAccountData,
    DateTime? fromDate,
    DateTime? toDate) {
  if (accountData == null) return null;
  Map<String, Investment> investmentBalances = {};
  Map<String, int> investmentIndices = {};
  Map<String, CategoryValue> categoryPaymentSums = {};
  Map<String, CategorySubcategoryValues> subcategoryPaymentSums = {};
  Map<String, CategoryValue> categoryReceiveSums = {};
  Map<String, CategorySubcategoryValues> subcategoryReceiveSums = {};
  for (int i = 0; i < accountData.investments.length; i++) {
    final investment = accountData.investments[i];
    investment.investedAmount = 0;
    investmentBalances[investment.name] = investment;
    investmentIndices[investment.name] = i;
  }
  for (Transaction transaction in accountData.transactions) {
    final transactionType = transactionTypeToString(transaction.entryType);
    if (transactionType == "payment" || transactionType == "receive") {
      if (fromDate != null &&
          compareDate(
                  DateTime.fromMillisecondsSinceEpoch(transaction.timestamp),
                  fromDate) <
              0) continue;
      if (toDate != null &&
          compareDate(
                  DateTime.fromMillisecondsSinceEpoch(transaction.timestamp),
                  toDate) >
              0) continue;
      if (transactionType == "payment") {
        if (!categoryPaymentSums.containsKey(transaction.category)) {
          categoryPaymentSums[transaction.category] =
              CategoryValue(transaction.category);
        }
        categoryPaymentSums[transaction.category]?.value +=
            transaction.outAmount;
        if (transaction.subcategory.isNotEmpty) {
          if (!subcategoryPaymentSums.containsKey(transaction.category)) {
            subcategoryPaymentSums[transaction.category] =
                CategorySubcategoryValues(transaction.category);
          }
          var subcategorySums =
              subcategoryPaymentSums[transaction.category]!.subcategorySums;
          var index = subcategorySums.indexWhere((subcategoryValue) =>
              subcategoryValue.categoryName == transaction.subcategory);
          if (index == -1) {
            subcategorySums.add(CategoryValue(transaction.subcategory));
            index = subcategorySums.length - 1;
          }
          subcategorySums[index].value += transaction.outAmount;
        }
      } else if (transactionType == "receive") {
        if (!categoryReceiveSums.containsKey(transaction.category)) {
          categoryReceiveSums[transaction.category] =
              CategoryValue(transaction.category);
        }
        categoryReceiveSums[transaction.category]?.value +=
            transaction.inAmount;
        if (transaction.subcategory.isNotEmpty) {
          if (!subcategoryReceiveSums.containsKey(transaction.category)) {
            subcategoryReceiveSums[transaction.category] =
                CategorySubcategoryValues(transaction.category);
          }
          var subcategorySums =
              subcategoryReceiveSums[transaction.category]!.subcategorySums;
          var index = subcategorySums.indexWhere((subcategoryValue) =>
              subcategoryValue.categoryName == transaction.subcategory);
          if (index == -1) {
            subcategorySums.add(CategoryValue(transaction.subcategory));
            index = subcategorySums.length - 1;
          }
          subcategorySums[index].value += transaction.inAmount;
        }
      }
    }
  }
  List<FixedInvestmentAccount> fixedInvestments = [];
  List<FluctuateInvestmentAccount> fluctuateInvestments = [];
  for (var investment in investmentBalances.entries) {
    if (investment.value.type == "fixed") {
      fixedInvestments.add(FixedInvestmentAccount(
          investment.value.name,
          investment.value.investedAmount,
          investmentIndices[investment.value.name]!,
          DateTime.parse(investment.value.startDate),
          DateTime.tryParse(investment.value.endDate),
          investment.value.rate,
          investment.value.interestBeforeEnd));
    } else {
      fluctuateInvestments.add(FluctuateInvestmentAccount(
          investment.value.name,
          investment.value.investedAmount,
          investmentIndices[investment.value.name]!,
          (investment.value.currentValue * 100).round()));
    }
  }

  return StatisticData(
      categoryPaymentSums.values.toList(),
      subcategoryPaymentSums.values.toList(),
      categoryReceiveSums.values.toList(),
      subcategoryReceiveSums.values.toList());
}

class StatisticalPage extends StatefulWidget {
  final AccountData? accountData;
  final AnalyzedAccountData? analyzedAccountData;

  StatisticalPage(
      {required this.accountData, required this.analyzedAccountData});

  @override
  State<StatefulWidget> createState() {
    return _StatisticalPageState();
  }
}

class _StatisticalPageState extends State<StatisticalPage> {
  StatisticData? _statisticData;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _update();
  }

  void _update() {
    _statisticData = statisticalAnalyze(
        widget.accountData, widget.analyzedAccountData, _fromDate, _toDate);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 200, child: Text("Current Sum:")),
          Text("${processMoney(widget.analyzedAccountData?.sum ?? 0)}")
        ]),
        Row(children: [
          Container(width: 200, child: Text("Fixed Investment Sum:")),
          Text(
              "${processMoney(widget.analyzedAccountData?.fixedInvestmentSum ?? 0)}")
        ]),
        Row(children: [
          Container(width: 200, child: Text("Fluctuate Investment Sum:")),
          Text(
              "${processMoney(widget.analyzedAccountData?.fluctuateInvestimentSum ?? 0)}")
        ]),
        Row(children: [
          Container(width: 200, child: Text("Fluctuate Current Sum:")),
          Text(
              "${processMoney(widget.analyzedAccountData?.fluctuateCurrentSum ?? 0)}")
        ]),
        Row(children: [
          Container(width: 200, child: Text("Total:")),
          Text("${processMoney(widget.analyzedAccountData?.total ?? 0)}")
        ]),
        Row(children: [
          Container(width: 50, child: Text("From")),
          TextButton(
              child: Text(
                  "${_fromDate != null ? formatDate(_fromDate!) : "Beginning"}"),
              onPressed: () async {
                _fromDate = await showDatePicker(
                        context: context,
                        initialDate: _fromDate ?? DateTime.now(),
                        firstDate: DateTime(1970),
                        lastDate: DateTime(9999, 12, 31)) ??
                    DateTime.now();
                _update();
              }),
          Container(width: 50, child: Text("To")),
          TextButton(
              child: Text("${_toDate != null ? formatDate(_toDate!) : "End"}"),
              onPressed: () async {
                _toDate = await showDatePicker(
                        context: context,
                        initialDate: _toDate ?? DateTime.now(),
                        firstDate: DateTime(1970),
                        lastDate: DateTime(9999, 12, 31)) ??
                    DateTime.now();
                _update();
              }),
        ]),
        SingleChildScrollView(
          child: Row(children: [
            Container(
              width: 700,
              height: 500,
              child: PieChart(PieChartData(
                  centerSpaceRadius: 0,
                  sections: _statisticData?.categoryPaymentSums
                      .map<PieChartSectionData>((categoryValue) {
                    return PieChartSectionData(
                        value: categoryValue.value / 100,
                        title:
                            "${categoryValue.categoryName} (${processMoney(categoryValue.value)})",
                        titleStyle: TextStyle(
                            color: Color((0xffffff -
                                    categoryValue.categoryName.hashCode %
                                        (0xffffff)) +
                                0xff000000)),
                        titlePositionPercentageOffset: 1.5,
                        color: Color(
                            categoryValue.categoryName.hashCode % (0xffffff) +
                                0xff000000),
                        radius: 150);
                  }).toList())),
            ),
            Container(
              width: 700,
              height: 500,
              child: PieChart(PieChartData(
                  centerSpaceRadius: 0,
                  sections: _statisticData?.categoryReceiveSums
                      .map<PieChartSectionData>((categoryValue) {
                    return PieChartSectionData(
                        value: categoryValue.value / 100,
                        title:
                            "${categoryValue.categoryName} (${processMoney(categoryValue.value)})",
                        titleStyle: TextStyle(
                            color: Color((0xffffff -
                                    categoryValue.categoryName.hashCode %
                                        (0xffffff)) +
                                0xff000000)),
                        titlePositionPercentageOffset: 1.5,
                        color: Color(
                            categoryValue.categoryName.hashCode % (0xffffff) +
                                0xff000000),
                        radius: 150);
                  }).toList())),
            ),
          ]),
        )
      ]),
    );
  }
}
