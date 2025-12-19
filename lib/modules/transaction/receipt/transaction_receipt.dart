import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TransactionReceiptContent extends StatelessWidget {
  final String transactionId;
  final String amount;
  final String receiverName;
  final String receiverContact;
  final String senderName;
  final String senderAddress;
  final String senderContact;
  final String date;
  final String status;
  final String exchangeRate;
  final String totalRecipientAmount;
  final String transferFee;
  final String purpose;
  final Function(Map<String, String>)? onConfirm;

  const TransactionReceiptContent({
    Key? key,
    required this.transactionId,
    required this.amount,
    required this.receiverName,
    required this.receiverContact,
    required this.senderName,
    required this.senderAddress,
    required this.senderContact,
    required this.date,
    required this.status,
    required this.exchangeRate,
    required this.totalRecipientAmount,
    required this.transferFee,
    required this.purpose,
    this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final idController = TextEditingController(text: transactionId);
    final amountController = TextEditingController(text: amount);
    final receiverController = TextEditingController(text: receiverName);
    final receiverContactController = TextEditingController(text: receiverContact);
    final senderController = TextEditingController(text: senderName);
    final senderAddressController = TextEditingController(text: senderAddress);
    final senderContactController = TextEditingController(text: senderContact);
    final dateController = TextEditingController(text: date);
    final statusController = TextEditingController(text: status);
    final exchangeRateController = TextEditingController(text: exchangeRate);
    final totalRecipientController = TextEditingController(text: totalRecipientAmount);
    final feeController = TextEditingController(text: transferFee);
    final purposeController = TextEditingController(text: purpose);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // --- Logo & Company ---
          Row(
            children: [
              Image.asset('assets/images/logo.jpg', height: 50),
              const SizedBox(width: 12),
              const Text(
                "Bior Investment LTD",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(thickness: 1.2),

          // --- Main Receipt Card ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Sender Details"),
                _editableField("Name", senderController),
                _editableField("Address", senderAddressController),
                _editableField("Contact", senderContactController),

                const SizedBox(height: 12),
                _sectionTitle("Receiver Details"),
                _editableField("Name", receiverController),
                _editableField("Contact", receiverContactController),

                const SizedBox(height: 12),
                _sectionTitle("Transaction Details"),
                _editableField("Amount Sent", amountController),
                _receiptRow("Transaction ID", idController.text),
                _editableField("Date", dateController),
                _editableField("Status", statusController),
                _receiptRow("Exchange Rate", exchangeRateController.text),
                _receiptRow("Total Recipient Amount", totalRecipientController.text),
                _receiptRow("Transfer Fee", feeController.text),
                _editableField("Purpose / Note", purposeController),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // --- Electronic Stamp Sample ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/e-stamp.png',
                  height: 40,
                  width: 40,
                  color: Colors.blueAccent,
                ),
                const Text(
                  "Electronic Stamp",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // --- Confirm & Cancel Buttons ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Cancel", style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () {
                  final updatedData = {
                    "transactionId": idController.text,
                    "amount": amountController.text,
                    "receiverName": receiverController.text,
                    "receiverContact": receiverContactController.text,
                    "senderName": senderController.text,
                    "senderAddress": senderAddressController.text,
                    "senderContact": senderContactController.text,
                    "date": dateController.text,
                    "status": statusController.text,
                    "exchangeRate": exchangeRateController.text,
                    "totalRecipientAmount": totalRecipientController.text,
                    "transferFee": feeController.text,
                    "purpose": purposeController.text,
                  };
                  if (onConfirm != null) onConfirm!(updatedData);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text("Confirm", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _editableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }
}
