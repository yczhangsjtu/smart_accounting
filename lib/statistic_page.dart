import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_accounting/data.dart';
import 'package:smart_accounting/utils.dart';

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
        SingleChildScrollView(
          child: Row(children: [
            Container(
              width: 700,
              height: 500,
              child: PieChart(PieChartData(
                  centerSpaceRadius: 0,
                  sections: widget.analyzedAccountData?.categoryPaymentSums
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
                  sections: widget.analyzedAccountData?.categoryReceiveSums
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
