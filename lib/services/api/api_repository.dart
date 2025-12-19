import 'dart:math' as logger;
import 'package:chat_app/Models/DatabaseHelper.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:chat_app/Models/upload_proof_model.dart';
import 'package:chat_app/services/api/api_constants.dart';
import 'package:chat_app/services/api/interceptors/dio_client.dart';
import 'package:chat_app/services/storage/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import '../../Models/AuthUser.dart';
import '../../Models/Country.dart';
import '../../Models/ProofStepGuide.dart';
import '../../Models/agent.dart';
import '../../Models/company_info.dart';
import '../../Models/transaction_model.dart';

class ApiRepository {
  final logger = Logger();

  final Dio _dio = Dio();
  RxList<Proof> proofUpdates = <Proof>[].obs;

  // LOGIN
  Future<Map<String, dynamic>> loginUser({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await Dio().post(
        ApiConstants.login,
        data: {
          'phone_number': phoneNumber.trim(),
          'password': password.trim(),
        },
        options: Options(
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final userJson = data['user'] as Map<String, dynamic>;
        final token = data['token'] as Map<String, dynamic>;

        // Create AuthUser
        final authUser = AuthUser.fromJson({
          ...userJson,
          'token': token,
        });

        // Save to Storage
        await StorageService.saveUserDetails(userJson);
        await StorageService.saveToken(token['access']);
        await StorageService.saveRefreshToken(token['refresh']);

        // Save to SQLite database
        try {
          await DatabaseHelper().insertAuthUser(authUser);
        } catch (_) {
          // Silently fail database save - user can still login
        }

        return {
          'success': true,
          'user': authUser,
          'token': token,
          'message': data['message'] ?? 'Login successful',
        };
      } else {
        final errorMsg = response.data?['message']?.toString() ?? 'Login failed';
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } on DioException catch (dioError) {
      // Handle network errors with user-friendly messages
      String errorMessage;

      switch (dioError.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;

        case DioExceptionType.connectionError:
          errorMessage = 'No internet connection. Please check your network settings.';
          break;

        case DioExceptionType.badCertificate:
          errorMessage = 'Security certificate error. Please try again later.';
          break;

        case DioExceptionType.badResponse:
          final statusCode = dioError.response?.statusCode;
          final serverMessage = dioError.response?.data?['message']?.toString();

          if (statusCode == 401) {
            errorMessage = 'Invalid phone number or password.';
          } else if (statusCode == 403) {
            errorMessage = 'Account is disabled or access denied.';
          } else if (statusCode == 404) {
            errorMessage = 'Account not found.';
          } else if (statusCode == 422) {
            errorMessage = 'Invalid input. Please check your details.';
          } else if (statusCode == 429) {
            errorMessage = 'Too many attempts. Please try again later.';
          } else if (statusCode! >= 500) {
            errorMessage = 'Server error. Please try again later.';
          } else if (serverMessage != null && serverMessage.isNotEmpty) {
            errorMessage = serverMessage;
          } else {
            errorMessage = 'Network error. Please try again.';
          }
          break;

        case DioExceptionType.cancel:
          errorMessage = 'Request cancelled.';
          break;

        default:
          errorMessage = 'Network error. Please check your connection and try again.';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      // Handle unexpected errors
      logger.e('Unexpected login error: $e');

      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// REGISTER
  Future<Map<String, dynamic>> registerUser({
    required String fullname,
    String? email,
    String? phoneNumber,
    required String password,
    required String confirmPassword,
    String? role,
    String? location,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'fullname': fullname,
        'password': password,
        'password_confirmation': confirmPassword,
      };
      if (email != null) data['email'] = email;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (role != null) data['role'] = role;
      if (location != null) data['location'] = location;

      final response = await DioClient.client.post(
        ApiConstants.register,
        data: data,
        options: Options(extra: {'showLoader': true}),
      );

      // Return a consistent map for both success and error
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'User registered successfully',
          'data': response.data['user'] ?? {},
          'token': response.data['token'] ?? {},
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      // Return failure map instead of throwing
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }


  /// LOGOUT
  Future<void> logoutUser() async {
    try {
      final token = await StorageService.getToken();
      final refreshToken = await StorageService.getRefreshToken();

      if (token == null || refreshToken == null) {
        throw Exception("No auth token found");
      }

      final response = await DioClient.client.post(
        ApiConstants.logout,
        data: {'refresh': refreshToken},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 205) {
        // Clear storage
        await StorageService.clearToken();
        await StorageService.clearRefreshToken();
        await StorageService.clearUserDetails();

        // Clear local database tables
        final dbHelper = DatabaseHelper();
        await dbHelper.clearProofs();
        await dbHelper.clearAuthUsers(); // clear users
        await dbHelper.clearAuthData();
        await dbHelper.clearProofSteps();
        await dbHelper.clearCompanyInfo();
        await dbHelper.clearAgents();
      } else {
        throw Exception('Logout failed with status ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Logout error: $e');
      rethrow;
    }
  }
  Future<dynamic> updateUser({
    required int userId,
    required dynamic userData,
    bool isMultipart = false,
  }) async {
    try {
      print('🚀 API Repository - updateUser called');
      print('   User ID: $userId');
      print('   Data type: ${userData.runtimeType}');

      // Enhanced debugging for FormData
      if (userData is dio.FormData) {
        print('📦 FormData details:');
        print('   Field count: ${userData.fields.length}');
        print('   File count: ${userData.files.length}');

        // Check each field
        for (var i = 0; i < userData.fields.length; i++) {
          final field = userData.fields[i];
          print('   Field $i: ${field.key} = ${field.value}');
        }

        // Check each file
        for (var i = 0; i < userData.files.length; i++) {
          final file = userData.files[i];
          print('   File $i: ${file.key} = ${file.value.filename}');
        }
      }

      // Get token with debugging
      final token = await StorageService.getToken();

      if (token == null) {
        print('❌ NO AUTH TOKEN - User might not be logged in');
        throw Exception("No auth token found");
      }

      // Prepare headers
      Map<String, dynamic> headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      // Add Content-Type for multipart
      if (isMultipart) {
        headers['Content-Type'] = 'multipart/form-data';
      }

      print('🔑 Request headers: $headers');
      print('➡️ Sending PUT to: ${ApiConstants.updateUserById(userId)}');

      final response = await DioClient.client.put(
        ApiConstants.updateUserById(userId),
        data: userData,
        options: Options(headers: headers),
      );

      print('✅ Response received: ${response.statusCode}');
      print('📄 Response data: ${response.data}');

      logger.i('Update user success: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
        print('❌ Response message: ${response.statusMessage}');
        print('❌ Response headers: ${response.headers}');
        throw Exception('Failed to update user: ${response.statusMessage}');
      }
    } catch (e, stacktrace) {
      print('❌ API Repository Error: $e');
      print('📝 Stack trace: $stacktrace');

      if (e is dio.DioException) {
        print('🔍 DioException details:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
        print('   Status: ${e.response?.statusCode}');
        print('   Headers: ${e.response?.headers}');
      }

      logger.e('Update user error', error: e, stackTrace: stacktrace);
      rethrow;
    }
  }

  // PASSWORD RESET USING EMAIL

  Future<dynamic> passwordResetRequest({
    required String email,
  }) async {
    try {

      final response = await DioClient.client.post(
        ApiConstants.password_reset_request,
        data: {
          'email': email,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {

      if (e is dio.DioException) {
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }

      rethrow;
    }
  }

  Future<dynamic> passwordResetConfirm({
    required String token,
    required String newPassword,
  }) async {
    try {
      print('🔐 Confirming Password Reset');

      final response = await DioClient.client.post(
        ApiConstants.password_reset_confirm,
        data: {
          'token': token,
          'new_password': newPassword,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e, stacktrace) {
      print('❌ Password Reset Confirm Error: $e');
      print('🧵 Stacktrace: $stacktrace');

      if (e is dio.DioException) {
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }

      rethrow;
    }
  }


  Future<void> deleteAccount() async {
    try {
      final token = await StorageService.getToken(); // Ensure you retrieve the token first

      final response = await DioClient.client.delete(
        ApiConstants.deleteOwnAccount,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await StorageService.clearAll(); // Clear tokens & local data
        logger.i('✅ Account deleted successfully');
      } else {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      logger.e('❌ Delete account failed: $e');
      rethrow;
    }
  }

/// Fetch upload proofs with optional filters and pagination
  Future<Proof?> uploadProof(FormData formData) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception("No auth token found. Please login again.");

      final response = await _dio.post(
        ApiConstants.uploadProof,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final proof = Proof.fromJson(response.data['data']);

        // ✅ Save locally for offline use
        await DatabaseHelper().insertProof(proof);

        // ✅ Update observable list (UI refresh)
        if (!proofUpdates.any((p) => p.id == proof.id)) {
          proofUpdates.insert(0, proof); // add to top
        }

        return proof;
      } else {
        throw Exception('Failed to upload proof. Status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Proof>> fetchAllProofs({bool forceRefresh = false}) async {
    final localProofs = await DatabaseHelper().getAllProofs();

    // Return local immediately if available
    if (localProofs.isNotEmpty && !forceRefresh) {
      // Fire and forget API sync
      _syncWithApi();
      return localProofs;
    }

    return _syncWithApi();
  }

  Future<List<Proof>> _syncWithApi() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception("No auth token found.");

      final response = await Dio().get(
        ApiConstants.proofs,
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data['data'];
        final proofs = jsonList.map((json) => Proof.fromJson(json)).toList();

        await DatabaseHelper().insertProofList(proofs);
        return proofs;
      } else {
        throw Exception("Failed to fetch proofs.");
      }
    } catch (e) {
      print("⚠️ Error fetching proofs: $e");
      return await DatabaseHelper().getAllProofs();
    }
  }



  Future<Map<String, dynamic>> searchUserByPhone(String phoneNumber) async {
    try {
      final token = await StorageService.getToken();

      final response = await DioClient.client.get(
        ApiConstants.searchUserByPhone,
        queryParameters: {'phone_number': phoneNumber},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      // Return whatever the API sends
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // If API returns 404 or other errors, just return success: false
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'User not found',
      };
    } catch (e) {
      // Unexpected errors
      return {
        'success': false,
        'message': 'Error searching user: $e',
      };
    }
  }

  Future<Proof?> updateProofStatus({
    required int proofId,
    required String status,
    String? statusNote,
    int? chargeRuleId,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final Map<String, dynamic> data = {
        'status': status,
        if (statusNote != null) 'status_note': statusNote,
        if (chargeRuleId != null) 'charge_rule': chargeRuleId,
      };

      final url = ApiConstants.updateProofStatus(proofId);

      final response = await DioClient.client.post(
        url,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          extra: {'showLoader': true},
        ),
      );


      if (response.statusCode == 200) {
        return Proof.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to update proof status. Status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception('API Error: $msg');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }


  // Fetch proof updates for a given user ID
  Future<List<dynamic>> fetchProofUpdates() async {
    try {
      // Get the saved token from storage
      final token = await StorageService.getToken(); // make sure you store it at login

      if (token == null || token.isEmpty) {
        throw Exception('No auth token found. User might not be logged in.');
      }

      final response = await DioClient.client.get(
        ApiConstants.proofs,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // add your token here
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        return data;
      } else {
        throw Exception('Failed to fetch proof updates. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching proof updates: $e');
    }
  }



  Future<List<Agent>> getAgents({bool forceRefresh = false}) async {
    // Try loading from local DB first
    final localData = await DatabaseHelper().getAllAgents();
    if (localData.isNotEmpty && !forceRefresh) {
      return localData; // return cached data
    }

    try {
      // Fetch from API
      final response = await DioClient.client.get(
        ApiConstants.agents,
        options: Options(extra: {'showLoader': false}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final agentsList = data.map((j) => Agent.fromJson(j)).toList();

        // Save to local DB
        await DatabaseHelper().clearAgents();
        await DatabaseHelper().insertAgentList(agentsList);

        return agentsList;
      } else {
        throw Exception('Failed to fetch agents from server');
      }
    } on DioException catch (e) {
      // On API error, fallback to local DB
      if (localData.isNotEmpty) {
        return localData;
      }
      throw Exception('Dio error: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      //Any other unexpected errors
      if (localData.isNotEmpty) {
        return localData;
      }
      throw Exception('Unexpected error fetching agents: $e');
    }
  }


  // Fetch countries directly from API
  Future<List<Country>> fetchCountriesFromApi() async {
    try {
      final response = await DioClient.client.get(
        ApiConstants.countries,
        options: Options(extra: {'showLoader': false}),
      );

      if (response.statusCode == 200) {
        final data = response.data as List; // assuming API returns a list
        return data.map((json) => Country.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch countries from server');
      }
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching countries: $e');
    }
  }

  // Fetch charge rules from backend
  Future<List<Map<String, dynamic>>> fetchChargeRules() async {
    try {
      final response = await DioClient.client.get(
        ApiConstants.chargeRules,
        options: Options(
          extra: {'showLoader': true}, // show loader while fetching
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as List; // directly cast the response as List
        return data.map((json) => json as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch charge rules from server');
      }
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching charge rules: $e');
    }
  }


  /// Fetch all company info sections
  Future<List<CompanyInfo>> getCompanyInfo({bool forceRefresh = false}) async {
    final localData = await DatabaseHelper().getAllCompanyInfo();
    if (localData.isNotEmpty && !forceRefresh) {
      return localData; // return offline data
    }

    try {
      final response = await DioClient.client.get(
        ApiConstants.company_info,
        options: Options(extra: {'showLoader': false}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final infoList = data.map((json) => CompanyInfo.fromJson(json)).toList();

        // save to local DB
        await DatabaseHelper().clearCompanyInfo();
        await DatabaseHelper().insertCompanyInfoList(infoList);

        return infoList;
      } else {
        throw Exception('Failed to fetch company info');
      }
    } catch (e) {
      return localData; // fallback offline
    }
  }

  /// GET all announcements
  Future<Map<String, dynamic>> getAnnouncements() async {
    try {
      final response = await DioClient.client.get(
        ApiConstants.get_announcements,
        options: Options(extra: {'showLoader': true}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data, // list of announcements
          'message': 'Fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch announcements',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

// GET logged-in user transactions with pagination
  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    int pageSize = 4,
  }) async {
    try {
      final response = await DioClient.client.get(
        ApiConstants.getTransactions,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
        options: Options(extra: {'showLoader': true}),
      );

      if (response.statusCode == 200) {
        final List list = response.data['data'];
        return list.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch transactions');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST: Create announcement
  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    String? description,
    String? imagePath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        if (description != null) 'description': description,
        if (imagePath != null)
          'image': await MultipartFile.fromFile(imagePath, filename: path.basename(imagePath)),
      });

      final response = await DioClient.client.post(
        ApiConstants.create_announcement,
        data: formData,
        options: Options(
          extra: {'showLoader': true},
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Announcement created successfully',
        };
      } else {
        if (response.data is Map<String, dynamic>) {
          return {
            'success': false,
            'message': response.data['message'] ?? 'Creation failed',
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'message': response.data.toString(),
            'statusCode': response.statusCode,
          };
        }
      }
    } on DioException catch (dioError) {
      return {
        'success': false,
        'message': dioError.response?.data ?? dioError.message,
        'statusCode': dioError.response?.statusCode,
      };
    } catch (e, stack) {
      print("[ERROR] $e");
      print(stack);
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }



  Future<Map<String, dynamic>> editAnnouncement({
    required int id,
    String? title,
    String? description,
    String? imagePath,
  }) async {
    try {
      print("[DEBUG] Editing announcement with id: $id");
      print("[DEBUG] Title: $title, Description: $description, ImagePath: $imagePath");

      FormData formData = FormData.fromMap({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (imagePath != null)
          'image': await MultipartFile.fromFile(imagePath, filename: 'announcement.jpg'),
      });

      final response = await DioClient.client.patch(
        ApiConstants.edit_announcement(id),
        data: formData,
        options: Options(
          extra: {'showLoader': true},
          validateStatus: (status) => true, // handle status manually
        ),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Announcement updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.data != null && response.data['message'] != null
              ? response.data['message']
              : 'Update failed',
        };
      }
    } catch (e, st) {
      print("[ERROR] Failed to edit announcement: $e");
      print(st);
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }


  /// DELETE: Announcement
  Future<Map<String, dynamic>> deleteAnnouncement(int id) async {
    try {

      final response = await DioClient.client.delete(
        ApiConstants.delete_announcement(id),
        options: Options(
          extra: {'showLoader': true},
          validateStatus: (status) => true,
        ),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Announcement deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.data != null && response.data['message'] != null
              ? response.data['message']
              : 'Deletion failed',
        };
      }
    } catch (e, st) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Fetch proof steps (with offline cache)
  Future<List<ProofStep>> getUploadProofSteps({bool forceRefresh = false}) async {
    // Read from local DB
    final localData = await DatabaseHelper().getAllProofSteps();

    if (localData.isNotEmpty && !forceRefresh) {
      return localData;
    }

    try {
      final response = await DioClient.client.get(
        ApiConstants.upload_proof_steps,
        options: Options(extra: {'showLoader': false}),
      );

      if (response.statusCode == 200) {
        // API RETURNS A RAW LIST
        final list = response.data as List;

        final steps = list.map((json) => ProofStep.fromJson(json)).toList();

        // Save into local DB
        await DatabaseHelper().clearProofSteps();
        await DatabaseHelper().insertProofStepsList(steps);

        return steps;
      } else {
        throw Exception("Failed to fetch proof steps");
      }
    } catch (e) {
      // fallback offline
      return localData;
    }
  }

  /// FETCH: WhatsApp Contact by ID
  Future<Map<String, dynamic>> getWhatsAppContact() async {
    try {
      final response = await DioClient.client.get(
        ApiConstants.getWhatsAppContact, // your GET URL
        options: Options(
          extra: {'showLoader': true},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        // Successfully fetched contact
        return {
          'success': true,
          'data': response.data['data'], // contact info
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to fetch contact',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
