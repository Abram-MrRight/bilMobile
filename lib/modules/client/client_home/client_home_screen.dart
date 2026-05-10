import 'package:carousel_slider/carousel_slider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Models/transaction_model.dart';
import '../../../services/api/api_repository.dart';
import '../../../shared/drawer/Drawer.dart';
import '../../announcements/announcement_controller.dart';
import '../../guide/GuideScreen.dart';
import '../upload_proofs/proofs_controller.dart';
import '../upload_proofs/proofs_screen.dart';
import 'client_home_controller.dart';
import 'package:lottie/lottie.dart';


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
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  final ClientHomeController controller =
  Get.put(ClientHomeController(apiRepository: ApiRepository()));

  final AnnouncementController announcementController =
  Get.put(AnnouncementController(apiRepository: ApiRepository()));

  int getTotalTransactions() {
    return transactions.length;
  }

  double getTotalAmount() {
    return transactions.fold(
      0.0,
          (sum, txn) => sum + txn.amountValue,
    );
  }

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
                      "Company News",
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
                      height: 150,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Uploaded Proofs",
                            value: "${controller.proofUpdates.length}",
                            icon: Icons.verified,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            title: "Total Amount",
                            value: "${getTotalAmount().toStringAsFixed(2)}",
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            title: "Transactions",
                            value: "${transactions.length}",
                            icon: Icons.swap_horiz,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          const SizedBox(height: 120),
          Positioned(
            bottom: 40,
            right: 20,
            child: Obx(() {
              return FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                  final confirm = await Get.dialog<bool>(
                    AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

                      title: Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.green,
                            size: 26,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Chat with Company',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),

                      content: const Text(
                        'You are about to start a WhatsApp conversation with the company. '
                            'Do you want to continue?',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),

                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => Get.back(result: true),
                          child: const Text(
                            'CHAT ON WHATSAPP',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10), // 👈 taller
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF009688), // teal
                Color(0xFF4CAF50), // green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ☰ MENU ICON
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),

                  // TITLE
                  Expanded(
                    child: Obx(() => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        "Welcome, ${controller.currentUserName.value.isNotEmpty
                            ? controller.currentUserName.value
                            : '...'} 👋",
                        key: ValueKey(controller.currentUserName.value),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                  ),

                  // 🏃 LOTTIE WITH GLOW
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.25),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: kToolbarHeight + 6,
                      width: kToolbarHeight + 30,
                      child: IgnorePointer(
                        child: Lottie.asset(
                          'assets/animations/boyRunning.json',
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: BuildDrawer(),
      body: screens[index],
      bottomNavigationBar: CurvedNavigationBar(
        key: navigatorKey,
        backgroundColor: Colors.transparent,
        color:   Color(0xFF4CAF50),
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
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

}
