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

void sortTransactions(List<Transaction> transactions) {
  transactions.sort((a, b) {
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

class AnalyzedAccountData {
  final List<Account> accounts;
  final List<Investment> investments;
  AnalyzedAccountData(this.accounts, this.investments);
}

AnalyzedAccountData? analyze(AccountData? accountData) {
  if (accountData == null) return null;
  Map<String, int> balances = {};
  Map<String, Investment> investmentBalances = {};
  for (Investment investment in accountData.investments) {
    investmentBalances[investment.name] = investment;
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
    if (transactionTypeToString(transaction.entryType) == "reset") {
      balances[transaction.outAccount] = transaction.resetTo;
    }
  }
  List<Account> accounts = [];
  int sum = 0;
  for (var accountName in balances.entries) {
    accounts.add(Account(accountName.key, accountName.value));
    sum += accountName.value;
  }
  accounts.add(Account("Sum", sum));
  List<Investment> investments = [];
  for (var investment in investmentBalances.entries) {
    investments.add(investment.value);
  }
  return AnalyzedAccountData(accounts, investments);
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
