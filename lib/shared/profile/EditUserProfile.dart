import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../modules/client/client_home/client_home_controller.dart';
import '../../services/api/api_constants.dart';

class UserProfileEditScreen extends StatefulWidget {
  const UserProfileEditScreen({super.key});

  @override
  State<UserProfileEditScreen> createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  final ClientHomeController controller = Get.find<ClientHomeController>();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController locationController;

  String role = '';
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: controller.currentUserName.value);
    phoneController = TextEditingController(text: controller.currentUserPhone.value);
    emailController = TextEditingController(text: controller.currentUserEmail.value);
    locationController = TextEditingController(text: controller.currentUserLocation.value);
    role = controller.currentUserRole.value;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    locationController.dispose();
    super.dispose();
  }

  bool get isSuperAdmin => role.toLowerCase() == 'super_admin';

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await controller.updateUser(
          userId: controller.currentUserId.value,
          name: nameController.text.trim(),
          phoneNumber: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
          role: isSuperAdmin ? role : null,
          profileImageFile: _pickedImage,
        );

        Get.back();
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          backgroundColor: Colors.teal,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to update profile. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.teal),
        filled: true,
        fillColor: Colors.teal.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
      ),
    );
  }
  ImageProvider? _getProfileImage() {
    if (_pickedImage != null) return FileImage(_pickedImage!);

    final imageUrl = controller.profileImage.value;
    if (imageUrl.isNotEmpty) {
      // Use ApiConstants to handle all URL formats
      return NetworkImage(
        ApiConstants.getFullMediaUrl(imageUrl, defaultPath: 'media/profile_images/default_avatar.png'),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String initial = controller.currentUserName.value.isNotEmpty
        ? controller.currentUserName.value[0].toUpperCase()
        : 'A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Your Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
              ),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: CircleAvatar(
                        key: ValueKey(_pickedImage ?? controller.profileImage.value),
                        radius: 75,
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage: _getProfileImage(),
                        child: _getProfileImage() == null
                            ? Text(initial, style: const TextStyle(fontSize: 40, color: Colors.white))
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.teal.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInputField(
                        icon: Icons.person,
                        label: 'Full Name',
                        controller: nameController,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        icon: Icons.phone,
                        label: 'Phone Number',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        icon: Icons.email,
                        label: 'Email',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Email is required';
                          if (!GetUtils.isEmail(value.trim())) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        icon: Icons.location_on,
                        label: 'Location',
                        controller: locationController,
                      ),
                      const SizedBox(height: 12),
                      if (isSuperAdmin)
                        DropdownButtonFormField<String>(
                          value: role,
                          items: ['client', 'admin', 'super_admin']
                              .map((r) => DropdownMenuItem(value: r, child: Text(r.capitalizeFirst ?? r)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => role = val);
                          },
                          decoration: InputDecoration(
                            labelText: 'Role',
                            labelStyle: const TextStyle(color: Colors.teal),
                            prefixIcon: const Icon(Icons.security, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
