import 'package:carousel_slider/carousel_slider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api/api_repository.dart';
import '../../../shared/drawer/Drawer.dart';
import '../../announcements/announcement_controller.dart';
import '../../guide/GuideScreen.dart';
import '../upload_proofs/proofs_controller.dart';
import '../upload_proofs/proofs_screen.dart';
import 'client_home_controller.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int index = 0;
  final navigatorKey = GlobalKey<CurvedNavigationBarState>();

  late final List<Widget> screens;

  final RxBool isSyncing = false.obs;

  final ClientHomeController controller =
  Get.put(ClientHomeController(apiRepository: ApiRepository()));

  final AnnouncementController announcementController =
  Get.put(AnnouncementController(apiRepository: ApiRepository()));

  @override
  void initState() {
    super.initState();

    // Fetch announcements when the screen loads
    announcementController.fetchAnnouncements();

    screens = [
      _buildHomeContent(),
      Builder(
        builder: (_) {
          final apiRepo = Get.find<ApiRepository>();
          if (!Get.isRegistered<UploadProofController>()) {
            Get.put(UploadProofController(apiRepository: apiRepo));
          }
          return UploadProofScreen();
        },
      ),
       GuideScreen(),
    ];
  }

  Widget _buildHomeContent() {
    // Default fallback announcements
    final List<Map<String, String>> defaultAnnouncements = [
      {
        "title": "New Feature Launched",
        "description": "We have introduced faster proof uploads!",
        "image": "https://picsum.photos/800/400"
      },
      {
        "title": "System Update",
        "description": "maintenance Schedules we shall always let you know.",
        "image": "https://picsum.photos/800/401"
      },
      {
        "title": "More features coming soon",
        "description": "Team is working hard and soon availing new features",
        "image": "https://picsum.photos/800/402"
      },
    ];

    return Obx(() {
      if (announcementController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final List<dynamic> announcementsList =
      announcementController.announcements.isNotEmpty
          ? List<dynamic>.from(announcementController.announcements)
          : defaultAnnouncements;

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await announcementController.fetchAnnouncements();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Company Announcements",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.9,
                      autoPlayInterval: const Duration(seconds: 4),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeFactor: 0.25,
                    ),
                    items: announcementsList.map((item) {
                      String imageUrl = (item is Map)
                          ? item['image']!
                          : (item as dynamic).image ?? "https://picsum.photos/800/400";

                      String title =
                      (item is Map) ? item['title']! : item.title;
                      String description =
                      (item is Map) ? item['description']! : item.description;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
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
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        description,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
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
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Obx(() {
              return FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                  final confirm = await Get.dialog<bool>(
                    AlertDialog(
                      title: const Text('Chat with Company'),
                      content: const Text(
                        'Do you want to start a WhatsApp chat with the company?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () => Get.back(result: true),
                          child: const Text('Chat'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  controller.isLoading.value = true;
                  try {
                    await controller.launchWhatsAppDynamic();
                  } finally {
                    controller.isLoading.value = false;
                  }
                },
                child: controller.isLoading.value
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const FaIcon(FontAwesomeIcons.whatsapp, size: 32),
              );
            }),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Navigation bar items
    final items = <Widget>[
      _buildNavItem(Icons.chat, 'Home', 0),
      _buildNavItem(Icons.settings, 'Proofs', 1),
      _buildNavItem(Icons.help, 'Guide', 2),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            "Welcome! ${controller.currentUserName.value.isNotEmpty ? controller.currentUserName.value : 'Loading...'}",
            key: ValueKey(controller.currentUserName.value),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        )),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
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
        color: Color(0xFF00BFA5),
        buttonBackgroundColor: Colors.white,
        items: items,
        index: index,
        onTap: (selectedIndex) {
          setState(() {
            index = selectedIndex;
          });

          if (selectedIndex == 1) {
            controller.proofUpdateCount.value = 0;
          }
        },
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Helper for nav item
  Widget _buildNavItem(IconData icon, String label, int itemIndex) {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: index == itemIndex ? Colors.red : Colors.white,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: index == itemIndex ? Colors.blueAccent : Colors.black87,
                ),
              ),
            ],
          ),
          // Proofs badge
          if (itemIndex == 1)
            Obx(() {
              if (controller.proofUpdateCount.value > 0) {
                return Positioned(
                  top: 8,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      controller.proofUpdateCount.value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
        ],
      ),
    );
  }
}
