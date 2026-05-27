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
import '../../guide/TransactionsScreen.dart';
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
  final ClientHomeController controller =
  Get.put(ClientHomeController(apiRepository: ApiRepository()));

  final AnnouncementController announcementController =
  Get.put(AnnouncementController(apiRepository: ApiRepository()));

  double getTotalAmount() {
    return controller.transactions.fold(
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
  // Add this method to refresh everything
  Future<void> _refreshAllData() async {
    await Future.wait([
      announcementController.fetchAnnouncements(),
      controller.loadTransactions(forceRefresh: true), // Force refresh transactions
      controller.fetchProofUpdates(),
    ]);
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
              await controller.loadTransactions(forceRefresh: true);
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
                  const SizedBox(height: 30),

                  // Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Overview",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Cards - Styled like GuideScreen cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildHomeCard(
                          title: "Uploaded Proofs",
                          value: "${controller.proofUpdates.length}",
                          icon: Icons.verified,
                          color: Colors.blue,
                          onTap: () {
                            setState(() {
                              index = 1;
                              controller.proofUpdateCount.value = 0;
                            });
                          },
                        ),
                        _buildHomeCard(
                          title: "Transactions",
                          value: "${controller.transactions.length}",
                          icon: Icons.swap_horiz,
                          color: Colors.orange,
                          onTap: () {
                            Get.to(() => TransactionsScreen());
                          },
                        ),
                        _buildHomeCard(
                          title: "Total Amount",
                          value: "${getTotalAmount().toStringAsFixed(2)}",
                          icon: Icons.attach_money,
                          color: Colors.green,
                          onTap: null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          const SizedBox(height: 90),
          Positioned(
            bottom: 40,
            right: 20,
            child: Obx(() {
              return FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: controller.isLoading.value
                    ? null
                    : () async {

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

  Widget _buildHomeCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      child: _HomeCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
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
              _buildModernNavItem(Icons.upload_file, 'Proofs', 1),
              _buildModernNavItem(Icons.info, 'Guide', 2),
            ],
          ),
        ),
      ),
    );
  }

  // Modern navigation item builder
  Widget _buildModernNavItem(IconData icon, String label, int itemIndex) {
    final isSelected = index == itemIndex;

    return InkWell(
      onTap: () {
        setState(() {
          index = itemIndex;
        });

        if (itemIndex == 1) {
          controller.proofUpdateCount.value = 0;
        }
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
            // Proofs badge
            if (itemIndex == 1)
              Obx(() {
                if (controller.proofUpdateCount.value > 0) {
                  return Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        controller.proofUpdateCount.value.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
      ),
    );
  }
}

class _HomeCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HomeCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<_HomeCard> with SingleTickerProviderStateMixin {
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
          // Show details dialog for non-clickable cards
          _showDetailsDialog();
        }
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
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
          children: [
            // Icon with colored background
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            // Value
            Text(
              widget.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.onTap != null ? widget.color : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
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