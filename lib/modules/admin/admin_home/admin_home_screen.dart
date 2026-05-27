import 'dart:async';
import 'dart:io';
import 'package:bilSend/Models/models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Models/announcements.dart';
import '../../../Models/transaction_model.dart';
import '../../../services/api/api_repository.dart';
import '../../../shared/drawer/Drawer.dart';
import '../../announcements/announcement_controller.dart';
import '../../client/client_home/client_home_controller.dart';
import '../../client/upload_proofs/ProofBadgeService.dart';
import '../../guide/GuideScreen.dart';
import '../../guide/TransactionsScreen.dart';
import '../admin_upload_proofs/admin_proofs_screen.dart';
import 'admin_home_controller.dart';

class AdminHomeScreen extends StatefulWidget {
  final VoidCallback? onProofsViewed;

  AdminHomeScreen({Key? key, this.onProofsViewed}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final RxBool isSyncing = false.obs;
  final ProofBadgeService badgeService = Get.find();
  final AdminHomeController controller =
  Get.put(AdminHomeController(apiRepository: ApiRepository()));
  final AnnouncementController announcementController =
  Get.put(AnnouncementController(apiRepository: ApiRepository()));

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  final ClientHomeController controller_count =
  Get.put(ClientHomeController(apiRepository: ApiRepository()));

  int index = 0;
  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    announcementController.fetchAnnouncements();
    screens = [
      _buildAnnouncementsContent(),
      AdminProofsScreen(
        onProofsViewed: () async {
          widget.onProofsViewed?.call();
        },
      ),
      GuideScreen(),
    ];
  }

  Widget _buildAnnouncementsContent() {
    return Obx(() {
      // Get proof updates count
      final AdminHomeController controller = Get.find<AdminHomeController>();

      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await announcementController.fetchAnnouncements();
            // await controller.fetchDashboardData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Announcements Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Company Updates",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    FloatingActionButton.small(
                      onPressed: _showCreateDialog,
                      child: const Icon(Icons.add, size: 20),
                      backgroundColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Announcements Carousel
                Obx(() {
                  if (announcementController.isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (announcementController.announcements.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text("No announcements yet."),
                      ),
                    );
                  }
                  return CarouselSlider(
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.9,
                      autoPlayInterval: const Duration(seconds: 5),
                      autoPlayCurve: Curves.fastOutSlowIn,
                    ),
                    items: announcementController.announcements.map((item) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                item.image ?? "https://picsum.photos/800/400",
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.broken_image, size: 50),
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.6),
                                      Colors.transparent
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description ?? '',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              _showEditDialog(item);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              _deleteAnnouncement(item);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),

                const SizedBox(height: 30),

                // Statistics Section
                const Text(
                  "Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Stats Cards - Using GridView for proper layout
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _AdminCard(
                      title: "Total Proofs",
                      value: "${controller_count.proofUpdates.length}",
                      icon: Icons.verified_outlined,
                      color: Colors.blue,
                      onTap: () => setState(() => index = 1),
                    ),
                    _AdminCard(
                      title: "Transactions",
                      value: "${controller.transactions.length}",
                      icon: Icons.swap_horiz,
                      color: Colors.orange,
                      onTap: () {
                        Get.to(() => TransactionsScreen());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    });
  }

// Add this method to build admin cards
  Widget _buildAdminCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      child: _AdminCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
        onTap: onTap,
      ),
    );
  }

// Add this method to show transactions details
  void _showTransactionsDetails() {
    Get.dialog(
      Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Recent Transactions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  final total = controller.transactions.fold(
                    0.0,
                        (sum, t) => sum + t.amountValue,
                  );

                  if (controller.transactions.isEmpty) {
                    return const Center(
                      child: Text("No transactions yet"),
                    );
                  }
                  return ListView.builder(
                    itemCount: controller.transactions.length,
                    itemBuilder: (context, index) {
                      final txn = controller.transactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text(
                              txn.amountValue.toStringAsFixed(0),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text("Transaction #${txn.id}"),
                          subtitle: Text(txn.senderName ?? ""),
                          trailing: Text(
                            "${txn.amountValue.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () => Get.back(),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showCreateDialog() {
    String title = '';
    String description = '';
    File? selectedImage;

    final ImagePicker picker = ImagePicker();

    Get.defaultDialog(
      title: '',
      contentPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      radius: 15,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(Icons.add_circle_outline, size: 50, color: Colors.green),
          ),
          const SizedBox(height: 10),
          const Text(
            "Create Announcement",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => title = val,
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => description = val,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                icon: const Icon(Icons.image),
                label: const Text("Pick Image"),
                onPressed: () async {
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    selectedImage = File(image.path);
                    setState(() {});
                    Get.snackbar(
                      "Image Selected",
                      "Image has been selected successfully",
                      backgroundColor: Colors.green.shade300,
                      colorText: Colors.white,
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
              const SizedBox(width: 10),
              selectedImage != null
                  ? Text(
                "Image selected",
                style: TextStyle(color: Colors.green.shade700),
              )
                  : const Text("No image"),
            ],
          ),
        ],
      ),
      confirm: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.check),
        label: const Text("Create"),
        onPressed: () async {
          if (title.isEmpty) {
            Get.snackbar(
              "Error",
              "Title cannot be empty",
              backgroundColor: Colors.red.shade300,
              colorText: Colors.white,
              icon: const Icon(Icons.error, color: Colors.white),
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }

          final success = await announcementController.createAnnouncement(
            title: title,
            description: description,
            imagePath: selectedImage?.path,
          );

          Get.back();

          if (success) {
            Get.snackbar(
              "Success",
              "Announcement created successfully!",
              backgroundColor: Colors.green.shade300,
              colorText: Colors.white,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              snackPosition: SnackPosition.BOTTOM,
            );
          } else {
            Get.snackbar(
              "Failed",
              "Failed to create announcement",
              backgroundColor: Colors.red.shade300,
              colorText: Colors.white,
              icon: const Icon(Icons.error, color: Colors.white),
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
      ),
      cancel: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.close),
        label: const Text("Cancel"),
        onPressed: () => Get.back(),
      ),
    );
  }

  void _showEditDialog(Announcement item) {
    String title = item.title;
    String description = item.description ?? '';
    final titleController = TextEditingController(text: title);
    final descController = TextEditingController(text: description);

    Get.defaultDialog(
      title: '',
      contentPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      radius: 15,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(Icons.edit, size: 50, color: Colors.orange),
          ),
          const SizedBox(height: 10),
          const Text(
            "Edit Announcement",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => title = val,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => description = val,
          ),
        ],
      ),
      confirm: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.update),
        label: const Text("Update"),
        onPressed: () async {
          await announcementController.editAnnouncement(
              id: item.id, title: title, description: description);
          Get.back();
          Get.snackbar(
            "Updated",
            "Announcement updated successfully!",
            backgroundColor: Colors.green.shade300,
            colorText: Colors.white,
            icon: const Icon(Icons.update, color: Colors.white),
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      ),
      cancel: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.close),
        label: const Text("Cancel"),
        onPressed: () => Get.back(),
      ),
    );
  }

  void _deleteAnnouncement(Announcement item) {
    Get.defaultDialog(
      title: '',
      contentPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      radius: 15,
      content: Column(
        children: [
          const Icon(Icons.delete_forever, size: 50, color: Colors.red),
          const SizedBox(height: 10),
          const Text(
            "Delete Announcement",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Are you sure you want to delete this announcement?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
      confirm: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.delete),
        label: const Text("Delete"),
        onPressed: () async {
          await announcementController.deleteAnnouncement(item.id);
          Get.back();
          Get.snackbar(
            "Deleted",
            "Announcement deleted successfully!",
            backgroundColor: Colors.green.shade300,
            colorText: Colors.white,
            icon: const Icon(Icons.delete, color: Colors.white),
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      ),
      cancel: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.close),
        label: const Text("Cancel"),
        onPressed: () => Get.back(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          "Welcome back ${controller.currentUserName.value.isNotEmpty ? controller.currentUserName.value : 'Loading...'}",
          style: const TextStyle(fontSize: 18.0, color: Colors.white),
        )),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: BuildDrawer(),
      body: screens[index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 18,
              offset: const Offset(0, -5),
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernNavItem(Icons.home, 'Home', 0),
              _buildModernNavItem(Icons.verified, 'Proofs', 1),
              _buildModernNavItem(Icons.help_outline, 'Guide', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernNavItem(IconData icon, String label, int itemIndex) {
    final isSelected = index == itemIndex;

    return InkWell(
      onTap: () {
        setState(() {
          index = itemIndex;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade700,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AdminCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          _showDetailsDialog();
        }
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_pressed ? 0.1 : 0.25),
              blurRadius: _pressed ? 4 : 12,
              offset: Offset(0, _pressed ? 2 : 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                widget.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.onTap != null ? widget.color : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog() {
    Get.dialog(
      Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.black.withOpacity(0.15),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, color: widget.color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}