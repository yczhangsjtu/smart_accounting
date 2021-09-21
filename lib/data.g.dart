// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['time', 'entryType', 'category', 'timestamp'],
  );
  return Transaction(
    json['time'] as String,
    json['outAccount'] as String? ?? '',
    json['inAccount'] as String? ?? '',
    json['outAmount'] as int? ?? 0,
    json['inAmount'] as int? ?? 0,
    json['entryType'] as int,
    json['category'] as String,
    json['subcategory'] as String? ?? '',
    json['comment'] as String? ?? '',
    json['resetTo'] as int? ?? 0,
    json['identifier'] as String? ?? '',
    json['timestamp'] as int,
  );
}

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'time': instance.time,
      'outAccount': instance.outAccount,
      'inAccount': instance.inAccount,
      'outAmount': instance.outAmount,
      'inAmount': instance.inAmount,
      'entryType': instance.entryType,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'comment': instance.comment,
      'resetTo': instance.resetTo,
      'identifier': instance.identifier,
      'timestamp': instance.timestamp,
    };

Investment _$InvestmentFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'type'],
  );
  return Investment(
    json['name'] as String,
    json['type'] as String,
    (json['currentValue'] as num?)?.toDouble() ?? 0.0,
    json['interestBeforeEnd'] as bool? ?? false,
    (json['rate'] as num?)?.toDouble() ?? 0.0,
    json['startDate'] as String? ?? '',
    json['endDate'] as String? ?? '',
  );
}

Map<String, dynamic> _$InvestmentToJson(Investment instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'currentValue': instance.currentValue,
      'interestBeforeEnd': instance.interestBeforeEnd,
      'rate': instance.rate,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };

AccountData _$AccountDataFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['categories', 'investments', 'transactions'],
  );
  return AccountData(
    (json['categories'] as List<dynamic>)
        .map((e) => (e as List<dynamic>).map((e) => e as String).toList())
        .toList(),
    (json['investments'] as List<dynamic>)
        .map((e) => Investment.fromJson(e as Map<String, dynamic>))
        .toList(),
    (json['transactions'] as List<dynamic>)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$AccountDataToJson(AccountData instance) =>
    <String, dynamic>{
      'categories': instance.categories,
      'investments': instance.investments,
      'transactions': instance.transactions,
    };
