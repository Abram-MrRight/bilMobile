import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Models/DatabaseHelper.dart';
import '../../client/upload_proofs/ProofBadgeService.dart';
import 'admin_proofs_controller.dart';

class AdminProofsScreen extends StatelessWidget {
  final VoidCallback? onProofsViewed;

   AdminProofsScreen({Key? key, this.onProofsViewed}) : super(key: key);

  final AdminProofsController controller =
  Get.put(AdminProofsController(apiRepository: Get.find()));

  final Map<String, Color> statusColors = const {
    'pending': Colors.orange,
    'money_received': Colors.green,
    'receiver_contacted': Colors.blueGrey,
  };

  final Map<String, String> statusLabels = const {
    'pending': 'P',
    'money_received': 'MR',
    'receiver_contacted': 'RC',
  };

  final Map<String, String> statusFullLabels = const {
    'pending': 'Pending',
    'money_received': 'Money Received',
    'receiver_contacted': 'Receiver Contacted',
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: statusLabels.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payments'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 5,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.tealAccent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey.shade600,
                isScrollable: false,
                tabs: statusLabels.entries.map((entry) {
                  final color = statusColors[entry.key] ?? Colors.grey;
                  return Obx(() {
                    int unreadCount = controller.displayedProofs
                        .where((p) => p.status.value == entry.key)
                        .length;

                    return Tab(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black,
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  });
                }).toList(),
              ),
            ),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final Map<String, List<dynamic>> proofsByStatus = {
            'pending': [],
            'money_received': [],
            'receiver_contacted': [],
            'money_delivered': [],
          };

          for (var proof in controller.displayedProofs) {
            final status = proof.status.value ?? 'pending';
            proofsByStatus[status]?.add(proof);
          }

          return TabBarView(
            children: statusLabels.keys.map((statusKey) {
              final proofs = proofsByStatus[statusKey]!;

              if (proofs.isEmpty) {
                return Center(
                    child: Text(
                        "No ${statusFullLabels[statusKey]} proofs.",
                        style: const TextStyle(color: Colors.grey)));
              }

              final groupedByDate = _groupProofsByDate(proofs);

              return RefreshIndicator(
                onRefresh: () async {
                  await controller.fetchProofsFromApiAndSync();
                },
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: groupedByDate.entries.map((entry) {
                    final dateLabel = entry.key;
                    final proofsForDate = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            dateLabel,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...proofsForDate.asMap().entries.map((proofEntry) {
                          final proof = proofEntry.value;
                          final isExpanded = false.obs;

                          return Obx(() {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black,
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () {
                                  isExpanded.value = !isExpanded.value;

                                  if (proof.isNewForAdmin.value) {
                                    proof.isNewForAdmin.value = false;
                                    DatabaseHelper().updateProof(proof);
                                    Get.find<ProofBadgeService>()
                                        .unreadProofCount
                                        .value--;
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              proof.senderName ?? "Unknown",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                          ),
                                          Text(
                                            "${proof.amount} ${proof.currency}",
                                            style: const TextStyle(
                                              color: Colors.teal,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          _buildStatusBadge(proof.status.value),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        proof.createdAt != null
                                            ? proof.createdAt
                                            .toString()
                                            .split('.')
                                            .first
                                            : "Unknown Date",
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                      if (isExpanded.value) ...[
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
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text("Receiver: ${proof.receiverName}"),
                                        Text(
                                            "Receiver Contact: ${proof.receiverContact}"),
                                        Text(
                                            "Receiver Email: ${proof.receiverEmail}"),
                                        if (proof.notes != null &&
                                            proof.notes!.isNotEmpty)
                                          Text("Notes: ${proof.notes}"),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _showStatusUpdateDialog(proof),
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Update Status'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            );
                          });
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        }),
      ),
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

  Widget _buildStatusBadge(String? status) {
    final Color bgColor = statusColors[status] ?? Colors.grey;
    final String displayText = statusFullLabels[status] ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(proof) {
    final AdminProofsController controller = Get.find();

    final statusOptions = {
      'money_delivered': 'Money Delivered',
      'receiver_contacted': 'Receiver Contacted',
      'money_received': 'Money Received',
      'pending': 'Pending',
    };

    String selectedStatus =
    proof.status.value.isNotEmpty ? proof.status.value : 'pending';

    // Close any existing bottom sheet first
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }

    Get.bottomSheet(
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...statusOptions.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedStatus == entry.key
                            ? Colors.teal.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: selectedStatus == entry.key
                              ? Colors.teal
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: RadioListTile<String>(
                        activeColor: Colors.teal,
                        title: Text(
                          entry.value,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selectedStatus == entry.key
                                ? Colors.teal.shade800
                                : Colors.grey.shade800,
                          ),
                        ),
                        value: entry.key,
                        groupValue: selectedStatus,
                        onChanged: (value) {
                          selectedStatus = value!;
                          Get.back();
                          _confirmStatusChange(proof, selectedStatus);
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _confirmStatusChange(proof, String newStatus) {
    final AdminProofsController controller = Get.find();

    final Map<String, String> statusNotes = {
      'pending': 'Money sent under review.',
      'receiver_contacted':
      'The receiver has been contacted and will receive the money soon.',
      'money_received': 'Money has been successfully received.',
      'money_delivered': 'Money has been successfully delivered to the receiver.',
    };

    final String defaultNote = statusNotes[newStatus] ?? 'Status updated via admin panel';

    if (newStatus == 'money_delivered') {
      _showChargeRuleSelection(proof, newStatus, defaultNote);
    } else {
      _showConfirmationDialog(proof, newStatus, defaultNote);
    }
  }

  void _showConfirmationDialog(proof, String newStatus, String defaultNote) {
    final AdminProofsController controller = Get.find();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent, // transparent for nice shadow
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 36,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Confirm Status Change',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'Are you sure you want to change the status to "${newStatus.replaceAll('_', ' ')}"?\n\nThis will attach the note:\n"$defaultNote"',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel Button
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Confirm Button
                  ElevatedButton(
                    onPressed: () async {
                      Get.back();
                      try {
                        await controller.updateProofStatus(
                          proofId: proof.id!,
                          status: newStatus,
                          statusNote: defaultNote,
                        );

                        proof.status.value = newStatus;
                        proof.statusNote.value = defaultNote;

                        Get.snackbar(
                          'Success',
                          'Proof status updated to "${newStatus.replaceAll('_', ' ')}"',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green.shade600,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          'Failed to update proof status: $e',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade600,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }


  void _showChargeRuleSelection(proof, String newStatus, String defaultNote) {
    final AdminProofsController controller = Get.find();

    // Set the active proof and fetch charge rules
    controller.activeProof = proof;
    controller.pendingStatus = newStatus;
    controller.defaultNote = defaultNote;

    // Fetch charge rules and show bottom sheet when complete
    controller.fetchChargeRules().then((_) {
      // Close any existing bottom sheet first
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }
      Get.bottomSheet(
        DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return ChargeRuleSelectionBottomSheet(
              scrollController: scrollController,
              controller: controller,
            );
          },
        ),
        isScrollControlled: true,
        enableDrag: true,
        isDismissible: true,
      );
    }).catchError((error) {
      Get.snackbar(
        'Error',
        'Failed to load charge rules: $error',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    });
  }
}

// Separate widget for charge rule selection
class ChargeRuleSelectionBottomSheet extends StatelessWidget {
  final ScrollController scrollController;
  final AdminProofsController controller;
  final RxInt selectedRuleId = 0.obs;

  ChargeRuleSelectionBottomSheet({
    Key? key,
    required this.scrollController,
    required this.controller,
  }) : super(key: key) {
    // Initialize selected rule ID safely
    if (controller.chargeRules.isNotEmpty) {
      selectedRuleId.value = controller.chargeRules.first['id'] as int;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Select Charge Rule",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (controller.chargeRules.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No charge rules available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              return DropdownButtonFormField<int>(
                value: selectedRuleId.value,
                isExpanded: true,
                menuMaxHeight: 300,
                items: controller.chargeRules.map((rule) {
                  return DropdownMenuItem<int>(
                    value: rule['id'] as int,
                    child: Text(
                      "${rule['currency']} | Min: ${rule['min_amount']} - Max: ${rule['max_amount']} | Charge: ${rule['charge_amount']}",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedRuleId.value = value;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              );
            }),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedRuleId.value > 0) {
                    Get.back();
                    controller.updateProofStatus(
                      proofId: controller.activeProof!.id!,
                      status: controller.pendingStatus!,
                      statusNote: controller.defaultNote!,
                      chargeRuleId: selectedRuleId.value,
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Please select a charge rule',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.shade600,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  shadowColor: Colors.teal.withOpacity(0.1),
                ),
                child: const Text(
                  "Confirm & Save",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}