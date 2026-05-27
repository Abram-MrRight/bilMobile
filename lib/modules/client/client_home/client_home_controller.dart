import 'dart:async';
import 'dart:io';
import 'package:bilSend/Routes/app_pages.dart';
import 'package:bilSend/services/api/api_constants.dart';
import 'package:bilSend/services/api/api_repository.dart';
import 'package:bilSend/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart' as dio;
import 'package:url_launcher/url_launcher.dart';

import '../../../Models/AuthUser.dart';
import '../../../Models/Contacts.dart';
import '../../../Models/DatabaseHelper.dart';
import '../../../Models/status_update_model.dart';
import '../../../Models/transaction_model.dart';
import '../../../services/api/interceptors/dio_client.dart';


class ClientHomeController extends GetxController {
  final ApiRepository apiRepository;
  final Logger logger = Logger();

  ClientHomeController({required this.apiRepository});

  final Rxn<AuthUser> currentAuthUser = Rxn<AuthUser>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString currentUserName = ''.obs;
  final RxInt currentUserId = 0.obs;
  final RxString currentUserPhone = ''.obs;
  final RxString currentUserEmail = ''.obs;
  final RxString currentUserLocation = ''.obs;
  final RxString currentUserRole = ''.obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  RxString profileImage = ''.obs;

  // --- NEW: For Bottom Navigation Bar ---
  final RxInt selectedPageIndex = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxInt proofUpdateCount = 0.obs;
  final RxList<StatusUpdate> proofUpdates = <StatusUpdate>[].obs;
  RxMap<int, String> _proofStatusMap = <int, String>{}.obs;
  final RxBool isSyncing = false.obs;
  Timer? _pollingTimer;

  RxList<WhatsAppContact> whatsappContacts = <WhatsAppContact>[].obs;

  AuthUser get currentUser => AuthUser(
    id: 0, // replace with actual user ID if available
    fullname: currentUserName.value,
    phoneNumber: currentUserPhone.value,
    profileImage: profileImage.value,
  );

  // List of pages/screens you'll navigate to via the bottom bar
  final List<String> pageRoutes = [
    Routes.CLIENTHOMESCEEN,
    Routes.UPLOADPROOF,
  ];


  @override
  void onInit() {
    super.onInit();
    _initializeChatData();

    // Load transactions when controller initializes
    loadTransactions();


    // Poll for announcements every 10 seconds
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      await fetchProofUpdates();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
    });

  }


  @override
  void onClose() {
    // _pollingTimer?.cancel();
    super.onClose();

  }


  Future<void> _initializeChatData() async {
    await loadUserDetails();
  }

  void updateProofCount(int count) {
    proofUpdateCount.value = count;
  }

  void markProofsAsRead() {
    proofUpdateCount.value = 0;
  }

  Future<void> fetchProofUpdates() async {
    try {
      final response = await apiRepository.fetchProofUpdates();
      final updates = (response as List)
          .map((json) => StatusUpdate.fromJson(json))
          .toList();

      proofUpdates.assignAll(updates);

      int newUpdates = 0;

      for (var proof in updates) {
        final oldStatus = _proofStatusMap[proof.id];

        if (oldStatus == null) {
          // New proof received
          newUpdates++;
        } else if (oldStatus != proof.status) {
          // Status changed
          newUpdates++;
        }

        // Update the map with the latest status
        _proofStatusMap[proof.id] = proof.status;
      }

      // Only increment badge if there are new or updated proofs
      if (newUpdates > 0) {
        proofUpdateCount.value += newUpdates;
      }

    } catch (e) {
      logger.e("Failed to fetch proof updates: $e");
    }
  }

  Future<void> loadUserDetails() async {
    try {
      final userDetails = await StorageService.getUserDetails();

      if (userDetails != null) {
        // Convert Map → AuthUser
        final user = AuthUser.fromJson(userDetails);

        // Store whole object
        currentAuthUser.value = user;

        currentUserName.value = userDetails['fullname'] ?? userDetails['name'] ?? '';
        currentUserId.value = userDetails['id'] as int? ?? 0;
        currentUserPhone.value = userDetails['phone_number'] ?? '';
        currentUserEmail.value = userDetails['email'] ?? '';
        currentUserLocation.value = userDetails['location'] ?? '';
        currentUserRole.value = userDetails['role'] ?? 'client';
        profileImage.value = user.fullProfileImageUrl;
      } else {
        logger.w('No user details found in storage');
      }
    } catch (e) {
      // Reset fields on failure
      currentUserName.value = '';
      currentUserId.value = 0;
      currentUserPhone.value = '';
      currentUserEmail.value = '';
      currentUserLocation.value = '';
      currentUserRole.value = 'client';
    }
  }


  // Method to change the selected tab
  void changePage(int index) {
    if (selectedPageIndex.value == index) return;
    selectedPageIndex.value = index;
    // Navigate to the corresponding route
    Get.offAllNamed(pageRoutes[index]);
  }

  Future<void> logout() async {
    errorMessage.value = '';

    try {
      await apiRepository.logoutUser();
      await StorageService.clearAll();
      Get.offAllNamed('/login');
    } catch (e, st) {
      errorMessage.value = 'Logout failed. Please try again.';
    }
  }
  Future<AuthUser?> getCurrentAuthUser() async {
    try {
      // Get user data from storage
      final userData = await StorageService.getUserDetails();
      if (userData != null) {
        return AuthUser.fromJson(userData);
      }

      // If not in storage, try to get from database
      final dbHelper = DatabaseHelper();
      final users = await dbHelper.getAllAuthUsers();
      if (users.isNotEmpty) {
        return users.first;
      }
    } catch (e) {
      print('❌ Error getting current AuthUser: $e');
    }
    return null;
  }


  Future<void> updateUser({
    required int userId,
    required String name,
    String? phoneNumber,
    String? email,
    String? location,
    String? role,
    File? profileImageFile,
  }) async {
    try {
      // Prepare userData map
      final Map<String, dynamic> userData = {
        'fullname': name,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        if (location != null && location.isNotEmpty) 'location': location,
        if (role != null && role.isNotEmpty) 'role': role,
        if (profileImageFile != null) 'image': profileImageFile.path,
      };

      // Send to repository (repository handles FormData conversion automatically)
      final updatedData = await apiRepository.updateUser(
        userId: userId,
        userData: userData,
      );

      final updatedUserJson = updatedData['data'];

      // Update local state
      currentUserName.value = updatedUserJson['fullname'] ?? name;
      currentUserPhone.value = updatedUserJson['phone_number'] ?? phoneNumber ?? '';
      currentUserEmail.value = updatedUserJson['email'] ?? email ?? '';
      currentUserLocation.value = updatedUserJson['location'] ?? location ?? '';
      currentUserRole.value = updatedUserJson['role'] ?? role ?? currentUserRole.value;

      // Update profile image path
      profileImage.value = ApiConstants.getFullMediaUrl(
        updatedUserJson['profile_image'],
        defaultPath: 'media/profile_images/default_avatar.png',
      );

    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }


  Future<void> deleteOwnAccount() async {
    try {
      await apiRepository.deleteAccount();
      Get.offAllNamed('/login');
      Get.snackbar(
        'Deleted',
        'Your account has been deleted.',
        backgroundColor: Colors.green,
        colorText: Colors.white,);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete account: $e');
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    try {
      final response = await apiRepository.updateUser(
        userId: currentUserId.value,
        userData: {
          'image': imageFile.path, // Just pass file path
        },
      );

      final updatedUserJson = response['data'];

      if (updatedUserJson['profile_image'] != null) {
        final path = updatedUserJson['profile_image'].toString();
        profileImage.value = ApiConstants.getFullMediaUrl(
          updatedUserJson['profile_image'],
          defaultPath: 'media/profile_images/default_avatar.png',
        );
      }

      await StorageService.saveUserDetails(updatedUserJson);
      Get.snackbar('Success', 'Profile image updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload profile image.');
      rethrow;
    }
  }


  Future<void> fetchWhatsAppContact() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await apiRepository.getWhatsAppContact();

      print('WhatsApp API Response: $result'); // Debug log

      if (result['success'] == true) {
        final data = result['data'];

        if (data is List && data.isNotEmpty) {
          whatsappContacts.assignAll(
            data.map((e) => WhatsAppContact.fromJson(e)).toList(),
          );
          print('Loaded ${whatsappContacts.length} contacts'); // Debug log
        } else {
          whatsappContacts.clear();
          print('No contacts found in response');
        }
      } else {
        whatsappContacts.clear();
        final errorMsg = result['message'] ?? 'Failed to load contacts';
        errorMessage.value = errorMsg;
        print('API Error: $errorMsg'); // Debug log

        // Show error to user
        Get.snackbar(
          'Error',
          errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      whatsappContacts.clear();
      errorMessage.value = 'Failed: $e';
      print('Exception in fetchWhatsAppContact: $e'); // Debug log

      Get.snackbar(
        'Error',
        'Failed to fetch WhatsApp contacts: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> launchWhatsAppDialog({String? message}) async {
    if (whatsappContacts.isEmpty) {
      await fetchWhatsAppContact();
    }

    if (whatsappContacts.isEmpty) {
      Get.snackbar('Error', 'No WhatsApp contacts available');
      return;
    }

    final selected = await Get.dialog<WhatsAppContact>(
      AlertDialog(
        title: const Text("Select Support"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: whatsappContacts.length,
            itemBuilder: (context, index) {
              final c = whatsappContacts[index];

              return ListTile(
                leading: CircleAvatar(child: Text("${index + 1}")),
                title: Text(c.name),
                subtitle: Text(c.phoneNumber),
                onTap: () => Get.back(result: c),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      await launchWhatsApp(
        phoneNumber: selected.phoneNumber,
        message: message,
      );
    }
  }
  Future<void> launchWhatsAppDynamic({String? message}) async {
    try {
      // ONLY show loading while fetching
      if (whatsappContacts.isEmpty) {
        isLoading.value = true;
        await fetchWhatsAppContact();
      }
    } finally {
      // stop loading BEFORE dialog opens
      isLoading.value = false;
    }

    if (whatsappContacts.isEmpty) {
      Get.snackbar(
        'Error',
        'No WhatsApp contacts available',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selected = await showWhatsAppContactsDialog(
      Get.context!,
      whatsappContacts,
    );

    if (selected != null) {
      await launchWhatsApp(
        phoneNumber: selected.phoneNumber,
        message: message,
      );
    }
  }
  Future<WhatsAppContact?> showWhatsAppContactsDialog(
      BuildContext context,
      List<WhatsAppContact> contacts,
      ) async {
    return await Get.dialog<WhatsAppContact>(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 450),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.support_agent, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Chat with us!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  )
                ],
              ),

              const Divider(),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final isSupport = index == 0;

                    return Align(
                      alignment: isSupport ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.75,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSupport ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSupport ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSupport ? const Color(0xFFE6F7E6) : const Color(0xFFE2E8F0),
                                  child: Text(
                                    contact.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isSupport ? const Color(0xFF2D6A2D) : const Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.name,
                                        style: TextStyle(
                                          color: const Color(0xFF1E293B),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        isSupport ? "Customer Support" : "Agentline",
                                        style: TextStyle(
                                          color: const Color(0xFF64748B),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: const Color(0xFF94A3B8)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    contact.phoneNumber,
                                    style: TextStyle(
                                      color: const Color(0xFF475569),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Get.back(result: contact),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D6A2D),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text("Start Chat"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  Future<void> launchWhatsApp({required String phoneNumber, String? message}) async {
    final encodedMessage = Uri.encodeComponent(message ?? 'Hello!');

    try {
      final whatsappUri = Uri.parse('whatsapp://send?phone=$phoneNumber&text=$encodedMessage');
      final whatsappAltUri = Uri.parse('whatsapp://send?phone=$phoneNumber');
      final webUri = Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage');
      final webAltUri = Uri.parse('https://wa.me/$phoneNumber');
      final apiUri = Uri.parse('https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage');

      if (await canLaunchUrl(whatsappUri)) { await launchUrl(whatsappUri); return; }
      if (await canLaunchUrl(whatsappAltUri)) { await launchUrl(whatsappAltUri); return; }
      if (await canLaunchUrl(webUri)) { await launchUrl(webUri); return; }
      if (await canLaunchUrl(webAltUri)) { await launchUrl(webAltUri); return; }
      if (await canLaunchUrl(apiUri)) { await launchUrl(apiUri); return; }

      await _openPlayStore();
    } catch (e) {
      print('Error launching WhatsApp: $e');
      Get.snackbar('Error', 'Failed to launch WhatsApp: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 3));
    }
  }

  Future<void> showSupportTeamDialog() async {
    if (whatsappContacts.isEmpty) {
      await fetchWhatsAppContact();
    }

    if (whatsappContacts.isEmpty) {
      Get.snackbar('Error', 'No support contacts available');
      return;
    }

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.support_agent, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    "Support Team",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),

              const Divider(),

              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      "Agents",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...whatsappContacts.map((c) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Text(
                                c.name.isNotEmpty ? c.name[0] : "?",
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    c.phoneNumber,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Get.back();
                                launchWhatsApp(
                                  phoneNumber: c.phoneNumber,
                                );
                              },
                              child: const Text("Chat"),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method to your ClientHomeController class
  Future<void> loadTransactions({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;

      final List<TransactionModel> fetchedTransactions =
      await getTransactions(forceRefresh: forceRefresh);

      transactions.assignAll(fetchedTransactions);

    } catch (e) {
      logger.e("Failed to load transactions: $e");
      errorMessage.value = "Failed to load transactions";
    } finally {
      isLoading.value = false;
    }
  }

// Update your getTransactions method to be an instance method
  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    int pageSize = 10,
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh) {
        final response = await DioClient.client.get(
          ApiConstants.getTransactions,
          queryParameters: {
            'page': page,
            'page_size': pageSize,
          },
        );

        final List list = response.data['data'];

        final transactions = list
            .map((json) => TransactionModel.fromJson(json))
            .toList();

        await DatabaseHelper().clearTransactions();
        await DatabaseHelper().insertTransactionList(transactions);

        return transactions;
      }

      // fallback always load local first
      final localData = await DatabaseHelper().getAllTransactions();
      if (localData.isNotEmpty) return localData;

      return await getTransactions(forceRefresh: true);

    } catch (e) {
      return await DatabaseHelper().getAllTransactions();
    }
  }

  Future<void> _openPlayStore() async {
    // Try direct Play Store app
    final playStoreAppUri = Uri.parse('market://details?id=com.whatsapp');

    // Fallback to web Play Store
    final playStoreWebUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.whatsapp'
    );

    if (await canLaunchUrl(playStoreAppUri)) {
      print('Opening Play Store app...');
      await launchUrl(playStoreAppUri);
    } else if (await canLaunchUrl(playStoreWebUri)) {
      print('Opening Play Store web...');
      await launchUrl(playStoreWebUri);
    } else {
      // Show error dialog instead of snackbar
      await Get.dialog(
        AlertDialog(
          title: Text('WhatsApp Not Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('WhatsApp is not installed on your device.'),
              SizedBox(height: 10),
              Text('Please install WhatsApp to use this feature.',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
class BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isLeft;

  BubbleTailPainter({
    required this.color,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path();

    if (isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, 0);
    }

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;


}
