import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Models/announcements.dart';
import '../../../services/api/api_repository.dart';
import '../../../shared/drawer/Drawer.dart';
import '../../announcements/announcement_controller.dart';
import '../../client/upload_proofs/ProofBadgeService.dart';
import '../../guide/GuideScreen.dart';
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

  int index = 0;
  final navigatorKey = GlobalKey<CurvedNavigationBarState>();
  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    announcementController.fetchAnnouncements();
    screens = [
      _buildAnnouncementsContent(),
      AdminProofsScreen(
        onProofsViewed: () async {
          // await _loadUnreadProofs();
          widget.onProofsViewed?.call();
        },
      ),
       GuideScreen(),
    ];
  }

  Widget _buildAnnouncementsContent() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Admin Announcements",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (announcementController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (announcementController.announcements.isEmpty) {
                  return const Center(child: Text("No announcements yet."));
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
                    return Stack(
                      children: [
                        Container(
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
                                    return Image.network(
                                      "https://picsum.photos/800/400",
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
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
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                _showEditDialog(item);
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
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
                        ),
                      ],
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 100),
            ],
          ),
        ),

        // Floating Add Button
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _showCreateDialog,
            child: const Icon(Icons.add),
            backgroundColor: Colors.green,
          ),
        ),
      ],
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
                    setState(() {}); // to refresh the dialog UI if needed
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

          // Call createAnnouncement with optional image path
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
    final items = <Widget>[
      _buildNavItem(Icons.chat, 'Home', 0),
      _buildNavItem(Icons.settings, 'Proofs', 1),
      _buildNavItem(Icons.help_outline, 'Guide', 2),
    ];

    return Scaffold(

      appBar: AppBar(
        title: Obx(() => Text(
        "Welcome back ${controller.currentUserName.value.isNotEmpty ? controller.currentUserName.value : 'Loading...'}",
          style: const TextStyle(fontSize: 18.0, color: Colors.black87),
        )),
        //Gradient goes here
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
      drawer: BuildDrawer(),
      body: screens[index],
      bottomNavigationBar: CurvedNavigationBar(
        key: navigatorKey,
        backgroundColor: Colors.transparent,
        color: Colors.teal,
        buttonBackgroundColor: Colors.white,
        items: items,
        index: index,
        onTap: (selectedIndex) {
          setState(() => index = selectedIndex);
        },
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int tabIndex) {
    return SizedBox(
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: index == tabIndex ? Colors.red : Colors.white),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: index == tabIndex ? Colors.blueAccent : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
