import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'utils.dart';
import 'data.dart';

Future<AccountData?> readAccountData() async {
  final typeGroup = XTypeGroup(label: 'json', extensions: ['json']);
  final file = await openFile(acceptedTypeGroups: [typeGroup]);
  try {
    final ret =
        AccountData.fromJson(json.decode(await file?.readAsString() ?? "{}"));
    sortTransactions(ret.transactions);
    return ret;
  } catch (e) {
    print("Exception in decoding the file: " + e.toString());
    return null;
  }
}
