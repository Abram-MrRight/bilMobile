import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:logger/logger.dart';

import '../../../Models/AuthUser.dart';
import '../../../Routes/app_pages.dart';
import '../../../services/api/api_repository.dart';
import '../../../services/storage/storage_service.dart';
import '../../admin/admin_home/admin_home_controller.dart';

class LoginController extends GetxController {
  final ApiRepository apiRepository;
  final logger = Logger();

  LoginController({required this.apiRepository});

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// Login with phone & password
  Future<void> loginUser(String phoneNumber, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await apiRepository.loginUser(
        phoneNumber: phoneNumber,
        password: password,
      );

      // Check if response is actually a Map and contains 'success' key
      if (response is Map<String, dynamic> && response.containsKey('success')) {
        if (response['success'] == true) {

          final user = response['user'];
          final tokenMap = response['token'];

          if (user != null && tokenMap != null) {

            final accessToken = tokenMap['access']?.toString();
            final refreshToken = tokenMap['refresh']?.toString();

            // Save user & token
            try {
              if (user is AuthUser) {
                // Convert AuthUser to Map for storage
                final userMap = user.toJson();
                await StorageService.saveUserDetails(userMap);
              } else if (user is Map<String, dynamic>) {
                await StorageService.saveUserDetails(user);
              } else {
                // Create a basic user map from the AuthUser object
                final userMap = {
                  'id': (user as AuthUser).id,
                  'fullname': (user as AuthUser).fullname,
                  'email': (user as AuthUser).email,
                  'phone_number': (user as AuthUser).phoneNumber,
                  'role': (user as AuthUser).role,
                  'location': (user as AuthUser).location,
                  'profile_image': (user as AuthUser).profileImage,
                };
                await StorageService.saveUserDetails(userMap);
              }

              await StorageService.saveToken(accessToken!);
              await StorageService.saveRefreshToken(refreshToken!);
            } catch (storageError) {
              throw Exception('Failed to save user data: $storageError');
            }

            // 🔹 Update AdminHomeController observables if registered
            if (Get.isRegistered<AdminHomeController>()) {
              await Get.find<AdminHomeController>().reloadCurrentUser();
            }

            // Navigate based on role
            String role;
            if (user is AuthUser) {
              role = user.role ?? 'client';
            } else if (user is Map<String, dynamic>) {
              role = user['role']?.toString() ?? 'client';
            } else {
              role = 'client';
            }

            if (role == 'admin') {
              Get.offAllNamed(Routes.ADMINHOMESCREEN);
            } else {
              Get.offAllNamed(Routes.CLIENTHOMESCEEN);
            }
          } else {
            errorMessage.value = 'Invalid response from server';
            _showSnackBar('Login Failed', errorMessage.value);
          }
        } else {
          final message = response['message']?.toString() ?? 'Login failed';
          errorMessage.value = message;
          _showSnackBar('Login Failed', message);
        }
      } else {
        // Response is not in expected format
        errorMessage.value = 'Invalid response from server';
        _showSnackBar('Error', errorMessage.value);
      }
    } catch (e) {

      errorMessage.value = 'An unexpected error occurred. Please try again.';
      _showSnackBar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  void _showSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}