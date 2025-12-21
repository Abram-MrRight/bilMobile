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
import '../../../Models/DatabaseHelper.dart';
import '../../../Models/status_update_model.dart';


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
  RxString profileImage = ''.obs;


  // --- NEW: For Bottom Navigation Bar ---
  final RxInt selectedPageIndex = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxInt proofUpdateCount = 0.obs;
  final RxList<StatusUpdate> proofUpdates = <StatusUpdate>[].obs;
  RxMap<int, String> _proofStatusMap = <int, String>{}.obs;
  final RxBool isSyncing = false.obs;
  Timer? _pollingTimer;

  // Store WhatsApp contact ID fetched from backend
  RxInt whatsappContactId = 0.obs;

  // Optionally, store the phone number once fetched
  RxString whatsappPhoneNumber = ''.obs;

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
      print('🔄 Starting user update...');
      print('   User ID: $userId');
      print('   Name: $name');
      print('   Phone: $phoneNumber');
      print('   Email: $email');
      print('   Location: $location');
      print('   Role: $role');
      print('   Has Image: ${profileImageFile != null}');

      // Prepare FormData for potential file upload
      final formData = dio.FormData.fromMap({
        '_method': 'post',
        'fullname': name,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        if (location != null && location.isNotEmpty) 'location': location,
        if (role != null && role.isNotEmpty) 'role': role,
        if (profileImageFile != null)
          'profile_image': await dio.MultipartFile.fromFile(
            profileImageFile.path,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      });

      // Debug: Check FormData contents
      print('📦 FormData created:');
      print('   Fields: ${formData.fields.length}');
      print('   Files: ${formData.files.length}');

      for (var field in formData.fields) {
        print('   ➡️ ${field.key}: ${field.value}');
      }
      for (var file in formData.files) {
        print('   📎 File: ${file.key}, Name: ${file.value.filename}');
      }

      final updatedData = await apiRepository.updateUser(
        userId: userId,
        userData: formData,
        isMultipart: true,
      );

      print('✅ API response received: $updatedData');

      final updatedUserJson = updatedData['data'];

      // Update local state
      currentUserName.value = updatedUserJson['fullname'] ?? name;
      currentUserPhone.value = updatedUserJson['phone_number'] ?? phoneNumber ?? '';
      currentUserEmail.value = updatedUserJson['email'] ?? email ?? '';
      currentUserLocation.value = updatedUserJson['location'] ?? location ?? '';
      currentUserRole.value = updatedUserJson['role'] ?? role ?? currentUserRole.value;

      // Update profile image path
      final profileImagePath = updatedUserJson['profile_image'];

      if (profileImagePath != null && profileImagePath.toString().isNotEmpty) {
        final path = profileImagePath.toString();

        if (path.startsWith('http://') || path.startsWith('https://')) {
          // Full URL returned by backend → use as-is
          profileImage.value = path;
        } else if (path.startsWith('/')) {
          // Relative path starting with / → append base URL
          profileImage.value = 'http://10.0.2.2:8000$path';
        } else {
          // Only filename → append base URL + storage folder
          profileImage.value = 'http://10.0.2.2:8000/storage/$path';
        }
      }

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
      final fileName = imageFile.path.split('/').last;
      final formData = dio.FormData.fromMap({
        'profile_image': await dio.MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await apiRepository.updateUser(
        userId: currentUserId.value,
        userData: formData,
        isMultipart: true,
      );

      final updatedUserJson = response['data'];

      if (updatedUserJson['profile_image'] != null) {
        final profileImagePath = updatedUserJson['profile_image'];
        profileImage.value =
        '${ApiConstants.baseUrl.replaceFirst('/api', '')}/storage/$profileImagePath';
      }

      await StorageService.saveUserDetails(updatedUserJson);

    } catch (e) {
      Get.snackbar('Error', 'Failed to upload profile image.');
      rethrow;
    }
  }

  Future<void> fetchWhatsAppContact() async {
    try {
      final result = await apiRepository.getWhatsAppContact(); // 🔥 NO ID

      if (result['success'] == true) {
        final data = result['data'];

        if (data is List && data.isNotEmpty) {
          final contact = data.first; // 🔥 only one contact

          whatsappContactId.value = contact['id'];
          whatsappPhoneNumber.value = contact['phone_number'];
        } else {
          Get.snackbar(
            'Error',
            'No WhatsApp contact found',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          result['message']?.toString() ?? 'Failed to fetch WhatsApp contact',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch WhatsApp contact: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  /// Launch WhatsApp dynamically using the stored contact ID
  Future<void> launchWhatsAppDynamic({String? message}) async {
    if (whatsappContactId.value == 0) {
      await fetchWhatsAppContact(); // fetch if not loaded yet
    }

    if (whatsappPhoneNumber.value.isNotEmpty) {
      await launchWhatsApp(phoneNumber: whatsappPhoneNumber.value, message: message);
    } else {
      Get.snackbar(
        'Error',
        'WhatsApp contact not available.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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