import 'package:bilSend/services/api/api_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Routes/app_pages.dart';
import '../../modules/client/client_home/client_home_controller.dart';
import 'ThemeController.dart';

class BuildDrawer extends StatelessWidget {
  final ThemeController themeController = Get.find<ThemeController>();
  final ClientHomeController controller =
  Get.put(ClientHomeController(apiRepository: ApiRepository()));

  BuildDrawer({Key? key}) : super(key: key);

  void _showLogoutConfirmation(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              // colors: [Colors.teal, Colors.white60],
              colors: [Colors.white, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 20, color: Colors.white),
              const SizedBox(height: 5),
              const Text(
                'Logout',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 5),
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(color: Colors.black, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                      minimumSize: const Size(30, 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(50, 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async{
                     await controller.logout();
                      Get.back();
                    },
                    child: const Text('Logout',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal:8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Colors.white, Colors.white60],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_forever, size: 20, color: Colors.white),
              const SizedBox(height: 8),
              const Text(
                'Delete Account',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 5),
              const Text(
                'Are you sure you want to delete your account? This cannot be undone.',
                style: TextStyle(color: Colors.black, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(50, 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 10)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(50, 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      controller.deleteOwnAccount();
                      Get.back();
                    },
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          Obx(() => ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white60, Colors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Obx(() {
                      final name = controller.currentUserName.value;
                      final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'A';

                      return  CircleAvatar(
                        radius: 75,
                        backgroundColor: Colors.blueGrey,
                        backgroundImage: controller.profileImage.value.isNotEmpty
                            ? NetworkImage(controller.profileImage.value)
                            : null,
                        child: controller.profileImage.value.isEmpty
                            ? Text(
                          controller.currentUserName.value.isNotEmpty
                              ? controller.currentUserName.value[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(fontSize: 40, color: Colors.black),
                        )
                            : null,
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() => Text(
                      controller.currentUserName.value.isNotEmpty
                          ? controller.currentUserName.value
                          : 'Abram',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                      controller.currentUserPhone.value.isNotEmpty
                          ? controller.currentUserPhone.value
                          : 'No phone number',
                      style: const TextStyle(color: Colors.red),
                    )),
                  ],
                ),
              ),
              Divider(),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('My Profile'),
                onTap: () {
                  Get.toNamed(Routes.PROFILE);
                },
              ),
              Divider(),
              // Settings section with expansion tile holding theme and logout
              ExpansionTile(
                leading: const Icon(Icons.person_2_outlined),
                title: const Text('Account'),

                children: [
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text(
                      'Delete Account',
                    ),
                    onTap: () => _showDeleteAccountConfirmation(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                ],
              ),
              Divider(),
              // Settings section with expansion tile holding theme and logout
              ExpansionTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                children: [
                  ListTile(
                    title: const Text('Dark Theme'),
                    trailing: Switch(
                      value: themeController.isDarkTheme,
                      onChanged: (value) {
                        themeController.toggleTheme();
                      },
                    ),
                    onTap: () {
                      themeController.toggleTheme();
                    },
                  ),
                ],
              ),
            ],
          )),
        ],
      ),
    );
  }
}
