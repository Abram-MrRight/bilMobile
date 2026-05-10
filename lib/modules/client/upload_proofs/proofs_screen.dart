import 'package:bilSend/modules/client/upload_proofs/proofs_controller.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../Models/Country.dart';
import '../../../Models/upload_proof_model.dart';
import '../client_home/client_home_controller.dart';

class UploadProofScreen extends StatelessWidget {
   UploadProofScreen({Key? key}) : super(key: key);

  final homeController = Get.find<ClientHomeController>();

  @override
  Widget build(BuildContext context) {
    final UploadProofController controller = Get.find();
    var expandedProofIds = <String>{}.obs;
    String formatMoney(dynamic amount) {
      final value = double.tryParse(amount.toString()) ?? 0.0;
      return NumberFormat('#,##0.00').format(value);
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Proofs'),
        centerTitle: true,
      ),
      body: Obx(() {
        // Loader on first load
        if (!controller.isFirstLoadComplete.value &&
            controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Empty state
        if (controller.displayedProofs.isEmpty &&
            !controller.isLoading.value) {
          return const Center(child: Text("No proofs uploaded yet."));
        }

        final groupedProofs =
        _groupProofsByDate(controller.displayedProofs);

        return RefreshIndicator(
          onRefresh: controller.refreshProofs,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...groupedProofs.entries.map((entry) {
                final dateLabel = entry.key;
                final proofs = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Date header
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...proofs.map((proof) {
                      final proofId = proof.id.toString();
                      final isExpanded =
                      controller.expandedProofIds.contains(proofId);

                      return Card(
                        elevation: 14,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                          color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (isExpanded) {
                              controller.expandedProofIds.remove(proofId);
                            } else {
                              controller.expandedProofIds.add(proofId);
                              controller.unreadStatusProofIds.remove(proofId);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.10),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    /// Sender + Amount
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            proof.senderName ?? "Unknown Sender",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "${formatMoney(proof.amount)} ${proof.currency}",
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    /// Status badge
                                    _buildStatusBadge(
                                      proof,
                                      unreadSet:
                                      controller.unreadStatusProofIds,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                /// Date
                                Text(
                                  proof.createdAt != null
                                      ? proof.createdAt
                                      .toString()
                                      .split('.')
                                      .first
                                      : "Unknown Date",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),

                                /// ───── EXPANDABLE DETAILS ─────
                                AnimatedSize(
                                  duration:
                                  const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: isExpanded
                                      ? Padding(
                                    padding:
                                    const EdgeInsets.only(top: 14),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Divider(),

                                        _infoRow("Receiver",
                                            proof.receiverName),
                                        _infoRow("Contact",
                                            proof.receiverContact),
                                        _infoRow("Email",
                                            proof.receiverEmail),

                                        if (proof.notes != null &&
                                            proof.notes!.isNotEmpty)
                                          _infoRow(
                                              "Notes", proof.notes),

                                        const SizedBox(height: 12),

                                        if (proof.imageUrl != null)
                                          ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            child: Image.network(
                                              proof.fullImageUrl!,
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.broken_image,
                                                size: 48,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),

              /// Pagination
              if (controller.displayedProofs.length <
                  controller.proofs.length)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: controller.viewMore,
                      child: const Text('View More'),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
      // Floating Action Button for adding a new proof
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProofDialog(context, controller),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, size: 30),
        tooltip: 'Add Proof',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );

  }

  Map<String, List<dynamic>> _groupProofsByDate(List proofs) {
    final Map<String, List<dynamic>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var proof in proofs) {
      final createdAt = proof.createdAt != null
          ? DateTime.tryParse(proof.createdAt.toString()) ?? today
          : today;

      final proofDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

      String label;
      if (proofDate == today) {
        label = 'Today';
      } else if (proofDate == yesterday) {
        label = 'Yesterday';
      } else {
        label =
        '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      }

      grouped.putIfAbsent(label, () => []).add(proof);
    }

    return grouped;
  }

  Widget _buildStatusBadge(Proof proof, {RxSet<String>? unreadSet}) {
    return Obx(() {
      Color bgColor;
      String displayText;

      switch (proof.status.value) {
        case 'pending':
          bgColor = Colors.orange;
          displayText = 'Pending';
          break;
        case 'money_received':
          bgColor = Colors.green;
          displayText = 'Money Received';
          break;
        case 'receiver_contacted':
          bgColor = Colors.blueGrey;
          displayText = 'Receiver Contacted';
          break;
        case 'money_delivered':
          bgColor = Colors.blue;
          displayText = 'Money Delivered';
          break;
        default:
          bgColor = Colors.grey;
          displayText = 'Unknown';
      }

      final isUnread = unreadSet?.contains(proof.id.toString()) ?? false;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(displayText, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 2),
          if (proof.statusNote.value.isNotEmpty && unreadSet != null)
            IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 18,
                color: isUnread ? Colors.red : Colors.black87,
              ),
              onPressed: () {
                unreadSet.remove(proof.id.toString());
                proof.isRead.value = true;

                Get.defaultDialog(
                  title: "Status Note",
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(proof.statusNote.value, style: const TextStyle(fontSize: 14)),
                  ),
                  textConfirm: "OK",
                  confirmTextColor: Colors.white,
                  onConfirm: () => Get.back(),
                );
              },
            ),
        ],
      );
    });

  }
  void _showProofDialog(BuildContext context, UploadProofController controller) {
    final senderNameController = TextEditingController(text: homeController.currentUserName.value,);
    final senderEmailController = TextEditingController(text: homeController.currentUserEmail.value,);
    final senderContactController = TextEditingController();

    // Receiver stays empty
    final receiverNameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final ImagePicker _picker = ImagePicker();

    // Use the controller's selectedCountry as source of truth
    final RxString selectedImagePath = ''.obs;
    final RxBool isSubmitting = false.obs;

    // Ensure countries are loaded
    if (controller.countryList.isEmpty) {
      controller.fetchCountries().then((countries) {
        controller.countryList.value = countries;
        if (countries.isNotEmpty) {
          controller.selectedCountry.value = countries.first;
        }
      });
    }

    Future<void> pickImage() async {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) selectedImagePath.value = image.path;
    }

    Future<void> submitProof() async {
      if (senderNameController.text.isEmpty ||
          senderContactController.text.isEmpty ||
          receiverNameController.text.isEmpty ||
          senderEmailController.text.isEmpty ||
          amountController.text.isEmpty ||
          selectedImagePath.value.isEmpty ||
          controller.selectedCountry.value == null) {
        Get.snackbar(
          "Error",
          "Please fill all fields, select a country and upload an image.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isSubmitting.value = true;

      try {
        final proof = await controller.uploadProof(
          senderName: senderNameController.text,
          receiverContact: senderContactController.text,
          receiverName: receiverNameController.text,
          senderEmail: senderEmailController.text,
          amount: amountController.text,
          currency: controller.selectedCountry.value!.code,
          notes: notesController.text,
          imagePath: selectedImagePath.value,
          countryId: controller.selectedCountry.value!.id,
        );

        if (proof != null) {
          Get.back();
          Get.snackbar(
            "Success",
            "Proof submitted successfully",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          // Only show failed snackbar if uploadProof actually failed
          Get.snackbar(
            "Failed",
            controller.errorMessage.value.isNotEmpty
                ? controller.errorMessage.value
                : "Upload failed. Try again.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        // Catch any unexpected errors
        Get.snackbar(
          "Error",
          "An error occurred: $e",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        isSubmitting.value = false;
      }
    }

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Send Payment Proof",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Sender Name
                  TextField(
                    controller: senderNameController,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'Sender Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // Receiver Contact
                  TextField(
                    controller: senderContactController,
                    decoration: const InputDecoration(
                        labelText: 'Receiver Contact',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  // Receiver Name
                  TextField(
                    controller: receiverNameController,
                    decoration: const InputDecoration(
                        labelText: 'Receiver Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // Receiver Email
                  TextField(
                    controller: senderEmailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'Sender Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.money),
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  // Country Dropdown (controller.selectedCountry used)
                  Obx(() => DropdownButtonFormField<Country>(
                    value: controller.selectedCountry.value,
                    items: controller.countryList
                        .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name),
                    ))
                        .toList(),
                    onChanged: (c) => controller.selectedCountry.value = c,
                    decoration: const InputDecoration(
                      labelText: 'Select Country',
                      border: OutlineInputBorder(),
                    ),
                  )),
                  const SizedBox(height: 12),

                  // Currency (read-only)
                  Obx(() => TextField(
                    controller: TextEditingController(
                        text: controller.selectedCountry.value?.code ?? ''),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                  )),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                        labelText: 'Note(Optional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Upload Image
                  Obx(() => ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: Text(selectedImagePath.value.isEmpty
                        ? "Upload screenshot of payment"
                        : "Image selected"),
                  )),
                  const SizedBox(height: 20),

                  // Submit Button
                  Obx(() => ElevatedButton.icon(
                    onPressed: isSubmitting.value ? null : submitProof,
                    icon: isSubmitting.value
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.send),
                    label:
                    Text(isSubmitting.value ? "Submitting..." : "Submit"),
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "N/A",
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

}
