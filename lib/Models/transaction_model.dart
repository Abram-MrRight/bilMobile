class TransactionModel {
  final int id;
  final String senderName;
  final String receiverName;
  final String? receiverContact;
  final String amount;
  final String currency;
  final String transactionReference;
  final String chargeAmount;
  final String netAmount;
  final DateTime confirmedAt;

  TransactionModel({
    required this.id,
    required this.senderName,
    required this.receiverName,
    this.receiverContact,
    required this.amount,
    required this.currency,
    required this.transactionReference,
    required this.chargeAmount,
    required this.netAmount,
    required this.confirmedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      senderName: json['sender_name'],
      receiverName: json['receiver_name'],
      receiverContact: json['receiver_contact'],
      amount: json['amount'],
      currency: json['currency'],
      transactionReference: json['transaction_reference'],
      chargeAmount: json['charge_amount'],
      netAmount: json['net_amount'],
      confirmedAt: DateTime.parse(json['confirmed_at']),
    );
  }
  double get amountValue =>
      double.tryParse(amount.replaceAll(',', '')) ?? 0.0;
}
