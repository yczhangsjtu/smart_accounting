import 'dart:convert';
import 'dart:typed_data';
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

void saveAccountData(AccountData? accountData) async {
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
