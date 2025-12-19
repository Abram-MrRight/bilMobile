import 'package:chat_app/Routes/app_pages.dart';
import 'package:chat_app/services/api/api_repository.dart';
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
        );
        Get.offAllNamed(Routes.LOGIN);
        return true;
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception:', '').trim(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
