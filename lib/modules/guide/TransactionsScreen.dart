import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../Models/transaction_model.dart';
import '../../services/api/api_repository.dart';
import 'package:path_provider/path_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ApiRepository apiRepository = ApiRepository();
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  int page = 1;
  final int pageSize = 5;

  @override
  void initState() {
    super.initState();
    fetchTransactions(); // Load first page
  }

  /// Fetch transactions page by page
  Future<void> fetchTransactions() async {
    if (!hasMore.value || isLoading.value) return;

    try {
      isLoading.value = true;

      final List<TransactionModel> fetched =
      await apiRepository.getTransactions(page: page, pageSize: pageSize);

      // Add only unique items to avoid duplicates
      final newItems = fetched.where((txn) =>
      !transactions.any((t) => t.transactionReference == txn.transactionReference)
      ).toList();

      if (newItems.isEmpty || fetched.length < pageSize) {
        hasMore.value = false; // No more pages
      } else {
        page++; // Increment page only if new items exist
      }

      transactions.addAll(newItems);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch transactions',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  double _parseAmount(String amount) =>
      double.tryParse(amount.replaceAll(',', '')) ?? 0.0;

  String _formatAmount(String amount) =>
      _parseAmount(amount).toStringAsFixed(2);

  /// Share or save PDF safely
  Future<void> _sharePdfFile(Uint8List pdfBytes, String filename) async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(pdfBytes);
        Get.snackbar(
          'Info',
          'PDF saved to ${file.path}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to share PDF: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Generate PDF receipt
  Future<void> _generateAndSharePDF(TransactionModel txn) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 55,
                        height: 55,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.teal,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Bior Investment LTD',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal,
                            ),
                          ),
                          pw.Text('OFFICIAL PAYMENT RECEIPT',
                              style: pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Date: ${_formatDate(txn.confirmedAt)}  •  Time: ${_formatTime(txn.confirmedAt)}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            'Reference: ${txn.transactionReference}',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Divider(),

                  // Details Table
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(3),
                    },
                    children: [
                      _tableRow('Transfer Amount',
                          '${_formatAmount(txn.amount)} ${txn.currency}', true),
                      _tableRow('Net Amount',
                          '${_formatAmount(txn.netAmount)} ${txn.currency}', true),
                      _tableRow('Sender (FROM)', txn.senderName),
                      _tableRow(
                          'Receiver (TO)',
                          '${txn.receiverName}\n${txn.receiverContact ?? ''}'),
                      _tableRow('Transaction Fee',
                          '${_formatAmount(txn.chargeAmount)} ${txn.currency}'),
                      _tableRow('Status', 'COMPLETED', false, PdfColors.green),
                      _tableRow('Date', _formatDate(txn.confirmedAt)),
                      _tableRow('Time', _formatTime(txn.confirmedAt)),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // QR Code
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data:
                          'Ref:${txn.transactionReference}|Amt:${txn.amount}|Curr:${txn.currency}',
                          width: 100,
                          height: 100,
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'SCAN TO VERIFY',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal),
                        ),
                      ],
                    ),
                  ),
                  pw.Spacer(),

                  // Signature
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _signatureBlock('Authorized Signature'),
                      _signatureBlock('Customer Signature'),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(),

                  // Footer
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Thank you for choosing Bior Investment LTD',
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'This receipt serves as an official confirmation of your transaction.',
                          style: pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'For support, contact us via our official channels.',
                          style: pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await _sharePdfFile(
          pdfBytes, 'receipt_${txn.transactionReference}.pdf');
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate receipt PDF: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  pw.TableRow _tableRow(String label, String value,
      [bool highlight = false, PdfColor? valueColor]) {
    return pw.TableRow(
      decoration: highlight ? pw.BoxDecoration(color: PdfColors.teal100) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: highlight ? 14 : 11,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _signatureBlock(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 160,
          height: 40,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  void _showTransactionDetails(TransactionModel txn) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transaction Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ref: ${txn.transactionReference}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSimpleDetailRow('Amount', '${_formatAmount(txn.amount)} ${txn.currency}'),
                  const SizedBox(height: 12),
                  _buildSimpleDetailRow('From', txn.senderName),
                  const SizedBox(height: 12),
                  _buildSimpleDetailRow('To', txn.receiverName),
                  const SizedBox(height: 12),
                  _buildSimpleDetailRow('Fee', '${_formatAmount(txn.chargeAmount)} ${txn.currency}'),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate PDF Receipt'),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _generateAndSharePDF(txn);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transactions'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (transactions.isEmpty && isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 20),
                const Text('No transactions found',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 10),
                Text('Your transaction history will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 25, bottom: 20),
          itemCount: transactions.length + (hasMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < transactions.length) {
              final txn = transactions[index];
              return GestureDetector(
                onTap: () => _showTransactionDetails(txn),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Material(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.monetization_on_outlined, color: Colors.teal),
                      title: Text('${_formatAmount(txn.amount)} ${txn.currency}'),
                      subtitle: Text('${txn.senderName} → ${txn.receiverName}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                ),
              );
            } else {
              // "View More" Button
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: hasMore.value
                      ? ElevatedButton(
                    onPressed: isLoading.value ? null : fetchTransactions,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: isLoading.value
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('View More'),
                  )
                      : const SizedBox.shrink(),
                ),
              );
            }
          },
        );
      }),
    );
  }
}
