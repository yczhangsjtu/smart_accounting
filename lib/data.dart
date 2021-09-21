import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';

@JsonSerializable()
class Transaction {
  Transaction(
    this.time,
    this.outAccount,
    this.inAccount,
    this.outAmount,
    this.inAmount,
    this.entryType,
    this.category,
    this.subcategory,
    this.comment,
    this.resetTo,
    this.identifier,
    this.timestamp,
  );

  @JsonKey(required: true)
  String time;

  @JsonKey(defaultValue: "")
  String outAccount;

  @JsonKey(defaultValue: "")
  String inAccount;

  @JsonKey(defaultValue: 0)
  int outAmount;

  @JsonKey(defaultValue: 0)
  int inAmount;

  @JsonKey(required: true)
  int entryType;

  @JsonKey(required: true)
  String category;

  @JsonKey(defaultValue: "")
  String subcategory;

  @JsonKey(defaultValue: "")
  String comment;

  @JsonKey(defaultValue: 0)
  int resetTo;

  @JsonKey(defaultValue: "")
  String identifier;

  @JsonKey(required: true)
  int timestamp;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}

@JsonSerializable()
class Investment {
  Investment(this.name, this.type, this.currentValue, this.interestBeforeEnd,
      this.rate, this.startDate, this.endDate);

  @JsonKey(required: true)
  String name;

  @JsonKey(required: true)
  String type;

  @JsonKey(defaultValue: 0.0)
  double currentValue;

  @JsonKey(ignore: true, defaultValue: 0)
  int investedAmount = 0;

  @JsonKey(defaultValue: false)
  bool interestBeforeEnd;

  @JsonKey(defaultValue: 0.0)
  double rate;

  @JsonKey(defaultValue: "")
  String startDate;

  @JsonKey(defaultValue: "")
  String endDate;

  factory Investment.fromJson(Map<String, dynamic> json) =>
      _$InvestmentFromJson(json);

  Map<String, dynamic> toJson() => _$InvestmentToJson(this);
}

@JsonSerializable()
class AccountData {
  AccountData(this.categories, this.investments, this.transactions);

  @JsonKey(required: true)
  List<List<String>> categories;

  @JsonKey(required: true)
  List<Investment> investments;

  @JsonKey(required: true)
  List<Transaction> transactions;

  factory AccountData.fromJson(Map<String, dynamic> json) =>
      _$AccountDataFromJson(json);

  Map<String, dynamic> toJson() => _$AccountDataToJson(this);
}
