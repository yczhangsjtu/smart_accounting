import 'dart:convert';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:enough_convert/enough_convert.dart';
import 'package:csv/csv.dart';
import 'utils.dart';
import 'data.dart';

Future<AccountData?> readAccountData() async {
  final typeGroup = XTypeGroup(label: 'json', extensions: ['json']);
  final file = await openFile(acceptedTypeGroups: [typeGroup]);
  if (file == null) return null;
  try {
    final ret = AccountData.fromJson(json.decode(await file.readAsString()));
    sortTransactions(ret.transactions);
    return ret;
  } catch (e) {
    print("Exception in decoding the file: " + e.toString());
    return null;
  }
}

Future saveAccountData(AccountData? accountData) async {
  sortTransactions(accountData?.transactions);
  final path = await getSavePath();
  if (path == null) return;
  final name = "smart_accounting";
  final encoder = JsonEncoder.withIndent("  ");
  final data =
      Uint8List.fromList(utf8.encode(encoder.convert(accountData?.toJson())));
  final mimeType = "text/plain";
  final file = XFile.fromData(data, name: name, mimeType: mimeType);
  await file.saveTo(path);
}

Future readAlipayData(AccountData? accountData, String account) async {
  if (accountData == null) return;
  final typeGroup = XTypeGroup(label: 'json', extensions: ['csv']);
  final file = await openFile(acceptedTypeGroups: [typeGroup]);
  try {
    String content = gbk.decode(await file?.readAsBytes() ?? []);
    final match = RegExp(r"交易记录明细列表-+\r\n").allMatches(content).first;
    content = content.substring(match.end);
    final end = content.indexOf("\r\n-----------");
    content = content.substring(0, end);
    final rows = CsvToListConverter(shouldParseNumbers: false).convert(content);
    for (var i = 0; i < rows.length; i++) {
      for (var j = 0; j < rows[0].length; j++) {
        if (rows[i][j] is String) rows[i][j] = rows[i][j].trim();
      }
    }

    Set<String> allIdentifiers = {};
    for (Transaction transaction in accountData.transactions) {
      if (transaction.identifier.startsWith("alipay")) {
        allIdentifiers.add(transaction.identifier);
      }
    }

    for (int i = 1; i < rows.length; i++) {
      Map<String, String> row = {};
      for (int j = 0; j < rows[0].length; j++) {
        row[rows[0][j]] = rows[i][j];
      }
      if (row['交易状态'] != '交易成功') continue;
      final identifier = "alipay" + (row["交易号"] ?? "");
      if (allIdentifiers.contains(identifier)) continue;
      final time = formatDateTime(DateTime.parse(row['交易创建时间'] ?? ""));
      String outAccount, inAccount;
      int outAmount, inAmount;
      int entryType;
      if (row['收/支'] == '支出') {
        outAccount = account;
        outAmount = int.parse(row['金额（元）']?.replaceFirst('.', '') ?? "0");
        inAccount = '';
        inAmount = 0;
        entryType = 0;
      } else if (row['资金状态'] == '已收入') {
        inAccount = account;
        inAmount = int.parse(row['金额（元）']?.replaceFirst('.', '') ?? "0");
        outAccount = '';
        outAmount = 0;
        entryType = 1;
      } else {
        continue;
      }

      String comment = "${row['交易对方']} ${row['商品名称']}";
      if (row['备注'] != '' && row['备注'] != null) comment += row['备注'] ?? "";

      String category = '其他';
      String subcategory = '';
      for (var entry in accountData.categories.entries) {
        final keyword = entry.key;
        final value = entry.value;
        int loc = comment.indexOf(keyword);
        if (loc >= 0) {
          loc = value.indexOf("-");
          if (loc >= 0) {
            category = value.substring(0, loc);
            subcategory = value.substring(loc + 1);
          } else {
            category = value;
            subcategory = '';
          }
          break;
        }
      }

      final transaction = Transaction(
          time,
          outAccount,
          inAccount,
          outAmount,
          inAmount,
          entryType,
          category,
          subcategory,
          comment,
          0,
          identifier,
          DateTime.parse(time).millisecondsSinceEpoch);

      accountData.transactions.add(transaction);
    }
  } catch (e) {
    print("Exception in decoding the file: " + e.toString());
    return null;
  }
}

Future readWechatData(AccountData? accountData, String account) async {
  if (accountData == null) return;
  final typeGroup = XTypeGroup(label: 'json', extensions: ['csv']);
  final file = await openFile(acceptedTypeGroups: [typeGroup]);
  try {
    String content = utf8.decode(await file?.readAsBytes() ?? []);
    final match = RegExp(r"微信支付账单明细列表-+,+\r\n").allMatches(content).first;
    content = content.substring(match.end);
    final rows = CsvToListConverter(shouldParseNumbers: false).convert(content);
    for (var i = 0; i < rows.length; i++) {
      for (var j = 0; j < rows[0].length; j++) {
        if (rows[i][j] is String) rows[i][j] = rows[i][j].trim();
      }
    }

    Set<String> allIdentifiers = {};
    for (Transaction transaction in accountData.transactions) {
      if (transaction.identifier.startsWith("wechat")) {
        allIdentifiers.add(transaction.identifier);
      }
    }

    for (int i = 1; i < rows.length; i++) {
      Map<String, String> row = {};
      for (int j = 0; j < rows[0].length; j++) {
        row[rows[0][j]] = rows[i][j];
      }
      if (row['当前状态'] != '支付成功' &&
          row['当前状态'] != '已存入零钱' &&
          row['当前状态'] != '已转账' &&
          row['当前状态'] != '已收钱' &&
          row['当前状态'] != '朋友已收钱') {
        continue;
      }
      final identifier = "wechat" + (row["交易单号"] ?? "");
      if (allIdentifiers.contains(identifier)) continue;
      final time = formatDateTime(DateTime.parse(row['交易时间'] ?? ""));
      String outAccount, inAccount;
      int outAmount, inAmount;
      int entryType;
      if (row['收/支'] == '支出') {
        outAccount = account;
        outAmount = int.parse(
            row['金额(元)']?.replaceFirst('¥', '').replaceFirst('.', '') ?? "0");
        inAccount = '';
        inAmount = 0;
        entryType = 0;
      } else if (row['收/支'] == '收入') {
        inAccount = account;
        inAmount = int.parse(
            row['金额(元)']?.replaceFirst('¥', '').replaceFirst('.', '') ?? "0");
        outAccount = '';
        outAmount = 0;
        entryType = 1;
      } else {
        continue;
      }

      String comment =
          "${row['交易对方']?.replaceFirst('"', '').replaceFirst('/', '')} ${row['商品']?.replaceFirst('"', '').replaceFirst('/', '')}";
      if (row['备注'] != '' && row['备注'] != null) comment += row['备注'] ?? "";
      if (row['备注'] != '"/"' && row['备注'] != null)
        comment += row['备注']!.replaceFirst('"', '').replaceFirst('/', '');

      String category = '其他';
      String subcategory = '';
      for (var entry in accountData.categories.entries) {
        final keyword = entry.key;
        final value = entry.value;
        int loc = comment.indexOf(keyword);
        if (loc >= 0) {
          loc = value.indexOf("-");
          if (loc >= 0) {
            category = value.substring(0, loc);
            subcategory = value.substring(loc + 1);
          } else {
            category = value;
            subcategory = '';
          }
          break;
        }
      }

      final transaction = Transaction(
          time,
          outAccount,
          inAccount,
          outAmount,
          inAmount,
          entryType,
          category,
          subcategory,
          comment,
          0,
          identifier,
          DateTime.parse(time).millisecondsSinceEpoch);

      accountData.transactions.add(transaction);
    }
  } catch (e) {
    print("Exception in decoding the file: " + e.toString());
    return null;
  }
}
