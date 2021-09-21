import 'dart:math';
import 'dart:core';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'data.dart';

String processMoney(int value) {
  if (value < 0) return "-${processMoney(-value)}";
  return "￥${value ~/ 100}.${(value % 100) ~/ 10}${value % 10}";
}

String moneyToString(int value) {
  if (value < 0) return "-${processMoney(-value)}";
  return "${value ~/ 100}.${(value % 100) ~/ 10}${value % 10}";
}

String transactionTypeToString(int value) {
  if (value == 0) {
    return "payment";
  } else if (value == 1) {
    return "receive";
  } else if (value == 2) {
    return "transfer";
  } else if (value == 3) {
    return "reset";
  } else if (value == 4) {
    return "reimburse";
  } else {
    return "ignore";
  }
}

int transactionTypeFromString(value) {
  if (value == "payment") {
    return 0;
  } else if (value == "receive") {
    return 1;
  } else if (value == "transfer") {
    return 2;
  } else if (value == "reset") {
    return 3;
  } else if (value == "reimburse") {
    return 4;
  } else {
    return 5;
  }
}

void sortTransactions(List<Transaction>? transactions) {
  transactions?.sort((a, b) {
    if (a.timestamp < b.timestamp) return -1;
    if (a.timestamp > b.timestamp) return 1;
    if (a.outAccount.compareTo(b.outAccount) < 0) return -1;
    if (a.outAccount.compareTo(b.outAccount) > 0) return 1;
    if (a.inAccount.compareTo(b.inAccount) < 0) return -1;
    if (a.inAccount.compareTo(b.inAccount) > 0) return 1;
    return 0;
  });
}

void reverseSortTransactions(List<Transaction>? transactions) {
  transactions?.sort((a, b) {
    if (a.timestamp < b.timestamp) return 1;
    if (a.timestamp > b.timestamp) return -1;
    if (a.outAccount.compareTo(b.outAccount) < 0) return 1;
    if (a.outAccount.compareTo(b.outAccount) > 0) return -1;
    if (a.inAccount.compareTo(b.inAccount) < 0) return 1;
    if (a.inAccount.compareTo(b.inAccount) > 0) return -1;
    return 0;
  });
}

class Account {
  final String name;
  final int balance;
  Account(this.name, this.balance);
}

class FixedInvestmentAccount {
  final String name;
  final int investedAmount;
  final int index;
  final DateTime startDate;
  final DateTime? endDate;
  final double rate;
  final bool interestBeforeEnd;
  FixedInvestmentAccount(this.name, this.investedAmount, this.index,
      this.startDate, this.endDate, this.rate, this.interestBeforeEnd);

  bool get hasEndDate {
    return endDate != null;
  }

  bool get expired {
    return endDate != null && endDate!.isBefore(DateTime.now());
  }

  int? get days {
    if (endDate == null) return null;
    return (endDate!.millisecondsSinceEpoch -
            startDate.millisecondsSinceEpoch) ~/
        (1000 * 3600 * 24);
  }

  int? get months {
    if (endDate == null) return null;
    return (endDate!.month - startDate.month) +
        (endDate!.year - startDate.year) * 12;
  }

  double? get years {
    final m = this.months;
    if (m == null) return null;
    return m / 12;
  }

  String? get periodStr {
    final m = this.months;
    if (m == null) return null;
    if (m < 12) return "$m Months";
    return "${(m / 12).toStringAsFixed(1)} Years";
  }

  int get interestPerYear {
    return (investedAmount * rate).round();
  }

  int? get totalProfit {
    final y = years;
    if (y == null) return null;
    return ((pow(1 + rate, y) - 1) * investedAmount).round();
  }
}

class FluctuateInvestmentAccount {
  final String name;
  final int investedAmount;
  final int index;
  final int currentAmount;
  FluctuateInvestmentAccount(
      this.name, this.investedAmount, this.index, this.currentAmount);

  int get profit {
    return currentAmount - investedAmount;
  }

  double get profitRate {
    return profit / investedAmount;
  }
}

class CategoryValue {
  String categoryName = "";
  int value = 0;
  CategoryValue(this.categoryName);
}

class CategorySubcategoryValues {
  String categoryName = "";
  List<CategoryValue> subcategorySums = [];
  CategorySubcategoryValues(this.categoryName);
}

class AnalyzedAccountData {
  final List<Account> accounts;
  final List<FixedInvestmentAccount> fixedInvestments;
  final List<FluctuateInvestmentAccount> fluctuateInvestments;
  final List<CategoryValue> categoryPaymentSums;
  final List<CategorySubcategoryValues> subcategoryPaymentSums;
  final List<CategoryValue> categoryReceiveSums;
  final List<CategorySubcategoryValues> subcategoryReceiveSums;
  final int sum;
  final int fixedInvestmentSum;
  final int fluctuateInvestimentSum;
  final int fluctuateCurrentSum;
  final int total;
  AnalyzedAccountData(
    this.accounts,
    this.fixedInvestments,
    this.fluctuateInvestments,
    this.categoryPaymentSums,
    this.subcategoryPaymentSums,
    this.categoryReceiveSums,
    this.subcategoryReceiveSums,
    this.sum,
    this.fixedInvestmentSum,
    this.fluctuateInvestimentSum,
    this.fluctuateCurrentSum,
    this.total,
  );
}

AnalyzedAccountData? analyze(AccountData? accountData) {
  if (accountData == null) return null;
  Map<String, int> balances = {};
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
    if (transaction.inAccount.isNotEmpty) {
      if (investmentBalances.containsKey(transaction.inAccount)) {
        int currentValue =
            investmentBalances[transaction.inAccount]?.investedAmount ?? 0;
        investmentBalances[transaction.inAccount]?.investedAmount =
            currentValue + transaction.inAmount;
      } else {
        int currentValue = balances[transaction.inAccount] ?? 0;
        balances[transaction.inAccount] = currentValue + transaction.inAmount;
      }
    }
    if (transaction.outAccount.isNotEmpty) {
      if (investmentBalances.containsKey(transaction.outAccount)) {
        int currentValue =
            investmentBalances[transaction.outAccount]?.investedAmount ?? 0;
        investmentBalances[transaction.outAccount]?.investedAmount =
            currentValue - transaction.inAmount;
      } else {
        int currentValue = balances[transaction.outAccount] ?? 0;
        balances[transaction.outAccount] = currentValue - transaction.outAmount;
      }
    }
    final transactionType = transactionTypeToString(transaction.entryType);
    if (transactionType == "reset") {
      balances[transaction.outAccount] = transaction.resetTo;
    } else if (transactionType == "payment") {
      if (!categoryPaymentSums.containsKey(transaction.category)) {
        categoryPaymentSums[transaction.category] =
            CategoryValue(transaction.category);
      }
      categoryPaymentSums[transaction.category]?.value += transaction.outAmount;
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
      categoryReceiveSums[transaction.category]?.value += transaction.inAmount;
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
  List<Account> accounts = [];
  int sum = 0;
  for (var accountName in balances.entries) {
    accounts.add(Account(accountName.key, accountName.value));
    sum += accountName.value;
  }
  accounts.add(Account("Sum", sum));
  List<FixedInvestmentAccount> fixedInvestments = [];
  List<FluctuateInvestmentAccount> fluctuateInvestments = [];
  int fixedInvestimentSum = 0,
      fluctuateInvestimentSum = 0,
      fluctuateCurrentSum = 0;
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
      fixedInvestimentSum += investment.value.investedAmount;
    } else {
      fluctuateInvestments.add(FluctuateInvestmentAccount(
          investment.value.name,
          investment.value.investedAmount,
          investmentIndices[investment.value.name]!,
          (investment.value.currentValue * 100).round()));
      fluctuateInvestimentSum += investment.value.investedAmount;
      fluctuateCurrentSum += (investment.value.currentValue * 100).round();
    }
  }
  return AnalyzedAccountData(
      accounts,
      fixedInvestments,
      fluctuateInvestments,
      categoryPaymentSums.values.toList(),
      subcategoryPaymentSums.values.toList(),
      categoryReceiveSums.values.toList(),
      subcategoryReceiveSums.values.toList(),
      sum,
      fixedInvestimentSum,
      fluctuateInvestimentSum,
      fluctuateCurrentSum,
      sum + fixedInvestimentSum + fluctuateCurrentSum);
}

enum Field {
  Time,
  InAccount,
  InAmount,
  OutAccount,
  OutAmount,
  Type,
  Category,
  Subcategory,
  Comment,
  ResetTo,
  All,
}

class Filter {
  final Field field;
  final String value;
  final bool precise;
  Filter(this.field, this.value, this.precise);

  bool filter(Transaction transaction) {
    if (field == Field.Time || field == Field.All) {
      if (precise
          ? transaction.time == value
          : transaction.time.contains(value))
        return true;
      else if (field != Field.All) return false;
    }
    if (field == Field.InAccount || field == Field.All) {
      if (precise
          ? transaction.inAccount == value
          : transaction.inAccount.contains(value))
        return true;
      else if (field != Field.All) return false;
    }
    if (field == Field.OutAccount || field == Field.All) {
      if (precise
          ? transaction.outAccount == value
          : transaction.outAccount.contains(value))
        return true;
      else if (field != Field.All) return false;
    }

    if (field == Field.Category || field == Field.All) {
      if (precise
          ? transaction.category == value
          : transaction.category.contains(value))
        return true;
      else if (field != Field.All) return false;
    }

    if (field == Field.Subcategory || field == Field.All) {
      if (precise
          ? transaction.subcategory == value
          : transaction.subcategory.contains(value))
        return true;
      else if (field != Field.All) return false;
    }

    if (field == Field.Comment || field == Field.All) {
      if (precise
          ? transaction.comment == value
          : transaction.comment.contains(value))
        return true;
      else if (field != Field.All) return false;
    }

    if (field == Field.InAmount || field == Field.All) {
      if (precise
          ? moneyToString(transaction.inAmount) == value
          : moneyToString(transaction.inAmount).contains(value))
        return true;
      else if (field != Field.All) return false;
    }
    if (field == Field.OutAmount || field == Field.All) {
      if (precise
          ? moneyToString(transaction.outAmount) == value
          : moneyToString(transaction.outAmount).contains(value))
        return true;
      else if (field != Field.All) return false;
    }

    if (field == Field.Type || field == Field.All) {
      if (precise
          ? transactionTypeToString(transaction.entryType) == value
          : transactionTypeToString(transaction.entryType).contains(value))
        return true;
      else if (field != Field.All) return false;
    }

    if (transaction.entryType == 3 &&
        (field == Field.ResetTo || field == Field.All)) {
      if (precise
          ? moneyToString(transaction.resetTo) == value
          : moneyToString(transaction.resetTo).contains(value))
        return true;
      else if (field != Field.All) return false;
    }
    return false;
  }
}

List<int> filter(List<Filter> filters, List<Transaction>? transactions) {
  if (transactions == null) return [];
  List<int> result = [];
  for (int i = 0; i < transactions.length; i++) {
    bool any = true;
    for (Filter filter in filters) {
      if (!filter.filter(transactions[i])) {
        any = false;
        break;
      }
    }
    if (any) result.add(i);
  }
  return result;
}

int str2cents(String? s) {
  if (s?.trim().isEmpty ?? true) {
    return 0;
  }
  return ((double.tryParse(s ?? "0") ?? 0) * 100).round();
}

String formatDate(DateTime date) => new DateFormat("yyyy-MM-dd").format(date);
String formatTime(DateTime date) => new DateFormat("HH:mm:ss").format(date);
String formatTimeOfDay(TimeOfDay time) =>
    "${time.hour}".padLeft(2, "0") +
    ":" +
    "${time.minute}".padLeft(2, "0") +
    ":00";
String formatDateTime(DateTime date) =>
    new DateFormat("yyyy-MM-dd HH:mm:ss").format(date);
String today() => formatDate(DateTime.now());
String nowstr() => formatTime(DateTime.now());
String todaynow() => formatDateTime(DateTime.now());
