import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../Routes/app_pages.dart';
import '../../../services/api/api_repository.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final ApiRepository apiRepository = ApiRepository();

  late String email;

  final TextEditingController otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool isLoading = false;
  bool isVerifying = false;

  Timer? _timer;
  int secondsLeft = 300; // 5 minutes
  bool canResend = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    email = args != null ? args['email'] ?? '' : '';

    if (email.isEmpty) {
      Future.delayed(Duration.zero, () {
        Get.snackbar(
          'Error',
          'Email not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.offAllNamed(Routes.LOGIN);
      });
    } else {
      startTimer();
      // Auto-focus OTP field after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ================= TIMER =================
  void startTimer() {
    _timer?.cancel();
    secondsLeft = 300;
    canResend = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft == 0) {
        timer.cancel();
        setState(() {
          canResend = true;
        });
      } else {
        setState(() {
          secondsLeft--;
        });
      }
    });
  }

  // ================= SEND OTP =================
  Future<void> sendOtp() async {
    setState(() => isLoading = true);

    final result = await apiRepository.generateOtp(email: email);

    setState(() => isLoading = false);

    if (result['success']) {
      startTimer();
      otpController.clear();

      Get.snackbar(
        'Success',
        'OTP sent to $email',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'],
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // ================= SUCCESS DIALOG =================
  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated success icon
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Verification Successful!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Your account has been verified successfully. You can now login to your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.offAllNamed(Routes.LOGIN);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Go to Login",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= VERIFY OTP =================
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter the verification code',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (otp.length != 6) {
      Get.snackbar(
        'Error',
        'Please enter complete 6-digit code',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() => isVerifying = true);

    final result = await apiRepository.verifyOtp(
      email: email,
      otpCode: otp,
    );

    setState(() => isVerifying = false);

    if (result['success']) {
      // Show success dialog instead of snackbar
      showSuccessDialog();
    } else {
      // Show error with shake animation effect
      Get.snackbar(
        'Verification Failed',
        result['message'] ?? 'Invalid OTP. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );

      // Clear OTP field on error for better UX
      otpController.clear();
    }
  }

  // ================= FORMAT TIMER =================
  String get timerText {
    if (secondsLeft <= 0) return "Code expired";
    final minutes = secondsLeft ~/ 60;
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Verify Account",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.teal),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with illustration
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.teal, Colors.tealAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

// Centered welcome section
                Column(
                  children: [
                    const Text(
                      "Check your email",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We've sent a verification code to",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          email,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // OTP Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: otpController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    enableActiveFill: true,
                    autoFocus: true,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.circle,
                      fieldHeight: 60,
                      fieldWidth: 50,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.grey[50],
                      selectedFillColor: Colors.white,
                      activeColor: Colors.teal,
                      selectedColor: Colors.teal,
                      inactiveColor: Colors.grey[300],
                      borderWidth: 2,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    onChanged: (value) {
                      // Auto-verify when 6 digits are entered
                      if (value.length == 6 && !isVerifying) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          verifyOtp();
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Timer section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: secondsLeft > 0
                        ? Colors.teal.withOpacity(0.05)
                        : Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        secondsLeft > 0 ? Icons.timer_outlined : Icons.timer_off_outlined,
                        color: secondsLeft > 0 ? Colors.teal : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timerText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: secondsLeft > 0 ? Colors.teal : Colors.red,
                        ),
                      ),
                      if (secondsLeft > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          "remaining",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (isVerifying || secondsLeft <= 0) ? null : verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: Colors.tealAccent,
                          width: 2.5,
                        ),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: isVerifying
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      "Verify & Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Resend section
                if (secondsLeft <= 0 || canResend)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Didn't receive the code?",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: canResend && !isLoading && !isVerifying
                              ? sendOtp
                              : null,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.teal,
                          ),
                          child: isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.teal,
                            ),
                          )
                              : const Text(
                            "Resend",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}