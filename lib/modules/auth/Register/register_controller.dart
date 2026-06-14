import 'package:bilSend/Routes/app_pages.dart';
import 'package:bilSend/services/api/api_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  final ApiRepository apiRepository;

  RegisterController({required this.apiRepository});

  final RxBool isLoading = false.obs;

  Future<bool> registerUser({
    required String fullname,
    String? email,
    String? phoneNumber,
    required String password,
    required String confirmPassword,
    String? location,
  }) async {
    try {
      isLoading.value = true;

      final response = await apiRepository.registerUser(
        fullname: fullname,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
        location: location,
      );

      if (response['success'] == true) {
        Get.snackbar(
          'Success',
          response['message'] ?? 'User registered successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return true;
      } else {
        // Extract meaningful error message from response
        String errorMessage = response['message'] ?? 'Registration failed';

        // Check for specific error cases
        if (errorMessage.toLowerCase().contains('email') &&
            errorMessage.toLowerCase().contains('already exists')) {
          errorMessage = 'This email is already registered. Please use a different email or login.';
        } else if (errorMessage.toLowerCase().contains('phone') &&
            errorMessage.toLowerCase().contains('already exists')) {
          errorMessage = 'This phone number is already registered. Please use a different number or login.';
        }

        Get.snackbar(
          'Registration Failed',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      // Handle different types of exceptions
      String errorMessage = e.toString().replaceAll('Exception:', '').trim();

      // Check for network errors
      if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Connection refused') ||
          errorMessage.contains('timeout')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      }
      // Check for duplicate entry based on error message patterns
      else if (errorMessage.toLowerCase().contains('duplicate') ||
          errorMessage.toLowerCase().contains('already exists') ||
          errorMessage.toLowerCase().contains('unique')) {
        if (errorMessage.toLowerCase().contains('email')) {
          errorMessage = 'This email address is already registered. Please use a different email.';
        } else if (errorMessage.toLowerCase().contains('phone')) {
          errorMessage = 'This phone number is already registered. Please use a different number.';
        } else {
          errorMessage = 'An account with this information already exists. Please try logging in.';
        }
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}