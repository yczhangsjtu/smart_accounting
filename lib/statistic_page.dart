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
      child: Column(children: [
        Text(
            "Current Sum: ${processMoney(widget.analyzedAccountData?.sum ?? 0)}"),
        Text(
            "Fixed Investment Sum: ${processMoney(widget.analyzedAccountData?.fixedInvestmentSum ?? 0)}"),
        Text(
            "Fluctuate Investment Sum: ${processMoney(widget.analyzedAccountData?.fluctuateInvestimentSum ?? 0)}"),
        Text(
            "Fluctuate Current Sum: ${processMoney(widget.analyzedAccountData?.fluctuateCurrentSum ?? 0)}"),
        Text("Total: ${processMoney(widget.analyzedAccountData?.total ?? 0)}")
      ]),
    );
  }
}
