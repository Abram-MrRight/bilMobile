import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../modules/client/client_home/client_home_controller.dart';
import 'EditUserProfile.dart';

class UserProfileScreen extends StatelessWidget {
  final ClientHomeController controller = Get.find<ClientHomeController>();

  UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient AppBar
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.to(() => const UserProfileEditScreen());
            },
          ),
        ],
      ),
      body: Obx(() {
        return Stack(
          children: [
            // Top gradient background
            Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  // Animated profile picture
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                      image: controller.profileImage.value.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(controller.profileImage.value),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: controller.profileImage.value.isEmpty
                        ? Center(
                      child: Text(
                        controller.currentUserName.value.isNotEmpty
                            ? controller.currentUserName.value[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                            fontSize: 60, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // User details card list
                  _buildAnimatedCard('Full Name', controller.currentUserName.value, Icons.person),
                  _buildAnimatedCard('Phone Number', controller.currentUserPhone.value, Icons.phone),
                  _buildAnimatedCard('Email', controller.currentUserEmail.value, Icons.email),
                  _buildAnimatedCard('Location', controller.currentUserLocation.value, Icons.location_on),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAnimatedCard(String title, String value, IconData icon) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Card(
            elevation: 4,
            shadowColor: Colors.purple.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(icon, color: Colors.white),
              ),
              title: Text(title,
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(value.isNotEmpty ? value : 'Not provided',
                  style: GoogleFonts.lato(fontSize: 14, color: Colors.black87)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
