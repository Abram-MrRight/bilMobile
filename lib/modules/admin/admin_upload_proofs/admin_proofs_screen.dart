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
                tabs: statusLabels.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  final color = statusColors[item.key] ?? Colors.grey;

                  return Obx(() {
                    int unreadCount = controller.displayedProofs
                        .where((p) => p.status.value == item.key)
                        .length;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // TAB BOX
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Text(
                                item.value,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),

                              if (unreadCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),

                        // ARROW CONNECTOR (except last tab)
                        if (index != statusLabels.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                      ],
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
      'pending': 'Pending',
      'money_received': 'Money Received',
      'receiver_contacted': 'Receiver Contacted',
      'money_delivered': 'Money Delivered',
    };

    String selectedStatus =
    proof.status.value.isNotEmpty ? proof.status.value : 'pending';

    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),

            // drag handle
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Update Delivery Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.teal.shade800,
              ),
            ),

            const SizedBox(height: 20),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: statusOptions.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((e) {
                    final index = e.key;
                    final entry = e.value;

                    final currentIndex =
                    statusOptions.keys.toList().indexOf(selectedStatus);

                    final isCompleted = index < currentIndex;
                    final isCurrent = index == currentIndex;
                    final isPending = index > currentIndex;

                    final isLast = index == statusOptions.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// LEFT SIDE TIMELINE
                          Column(
                            children: [

                              /// STEP CIRCLE
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted || isCurrent
                                      ? Colors.teal
                                      : Colors.grey.shade300,
                                  boxShadow: isCurrent
                                      ? [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    )
                                  ]
                                      : [],
                                ),
                                child: Icon(
                                  isCompleted
                                      ? Icons.check
                                      : isCurrent
                                      ? Icons.radio_button_checked
                                      : Icons.circle_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),

                              /// CONNECTOR + UPWARD ARROW
                              if (!isLast)
                                Column(
                                  children: [

                                    Container(
                                      width: 3,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: (isCompleted || isCurrent)
                                            ? Colors.teal
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),

                                    Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      size: 24,
                                      color: (isCompleted || isCurrent)
                                          ? Colors.teal
                                          : Colors.grey.shade400,
                                    ),

                                    Container(
                                      width: 3,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: (isCompleted || isCurrent)
                                            ? Colors.teal
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          const SizedBox(width: 14),

                          /// RIGHT CARD
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                selectedStatus = entry.key;
                                Get.back();
                                _confirmStatusChange(proof, selectedStatus);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(bottom: 18),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.teal.shade50
                                      : isCompleted
                                      ? Colors.green.shade50
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCurrent
                                        ? Colors.teal
                                        : isCompleted
                                        ? Colors.green
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [

                                    /// TITLE ROW
                                    Row(
                                      children: [

                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: isCurrent
                                                  ? Colors.teal.shade800
                                                  : isCompleted
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade800,
                                            ),
                                          ),
                                        ),

                                        if (isCompleted)
                                          const Icon(
                                            Icons.verified,
                                            color: Colors.green,
                                            size: 18,
                                          ),

                                        if (isCurrent)
                                          Icon(
                                            Icons.timelapse,
                                            color: Colors.teal.shade700,
                                            size: 18,
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    /// HINT TEXT
                                    Text(
                                      _getStatusHint(entry.key),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.4,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),

                                    /// CURRENT STATUS LABEL
                                    if (isCurrent) ...[
                                      const SizedBox(height: 10),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.teal,
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          "CURRENT STATUS",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // cancel button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
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

      _showConfirmationDialog(proof, newStatus, defaultNote);
  }

  void _showConfirmationDialog(proof, String newStatus, String defaultNote) {
    final AdminProofsController controller = Get.find();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
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
              Text(
                'Are you sure you want to change the status to "${newStatus.replaceAll('_', ' ')}"?\n\nThis will attach the note:\n"$defaultNote"',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
                  ElevatedButton(
                    onPressed: () async {
                      Get.back(); // Close dialog

                      // Show loading indicator
                      Get.dialog(
                        const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );

                      try {
                        // Step 1: Update via API
                        final response = await controller.updateProofStatus(
                          proofId: proof.id!,
                          status: newStatus.trim(),
                          statusNote: defaultNote,
                        );

                        Get.back(); // Close loading dialog

                        if (response == null) {
                          // success (your controller returns null on success)

                          await controller.fetchProofsFromApiAndSync();

                          Get.snackbar(
                            'Success',
                            'Status updated to ${newStatus.replaceAll('_', ' ')}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            response,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      }  catch (e) {
                        Get.back(); // Close loading dialog if open

                        // Revert local state if API failed
                        proof.status.value = proof.status.value; // Force refresh

                        Get.snackbar(
                          'Error',
                          'Failed to update proof status: ${e.toString()}',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade600,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 4),
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
  String _getStatusHint(String status) {
    switch (status) {
      case 'pending':
        return 'Transaction is waiting for processing';
      case 'money_received':
        return 'Funds have been received successfully';
      case 'receiver_contacted':
        return 'Receiver has been notified';
      case 'money_delivered':
        return 'Money successfully delivered';
      default:
        return '';
    }
  }
}