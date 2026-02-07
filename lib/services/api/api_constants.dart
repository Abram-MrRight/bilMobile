class ApiConstants {
  // 🌐 Base URL

  // Staging API base URL
  static const String baseUrl ='http://10.0.2.2:8000/api';

  // Public base URL for assets (images, audio, files)
  static const String publicBaseUrl ='http://10.0.2.2:8000';

  // static const String baseUrl ='https://staging.atong-abraham.site/api';
  //
  // // Public base URL for assets (images, audio, files)
  // static const String publicBaseUrl ='https://staging.atong-abraham.site';

  // static const String baseUrl = 'http://10.161.208.154:8000/api';
  // // Public base URL for assets (e.g., images, audio files)   
  // static const String publicBaseUrl = 'http://10.161.208.154:8000';

  // 🔐 AUTHENTICATION

  /// POST: Login with phone_number & password
  static const String login = '$baseUrl/auth/login/';

  /// POST: Register with phone/email + password
  static const String register = '$baseUrl/auth/register/';

  /// POST: Login using a token (Sanctum-protected)
  static const String loginWithToken = '$baseUrl/auth/login_with_token';

  /// GET: Logout (Sanctum-protected)
  static const String logout = '$baseUrl/auth/logout/';

  // USERS

// GET: List all users
  static const String users = '$baseUrl/users/';

// GET: Get single user by ID
  static String getUserById(int id) => '$baseUrl/users/$id/';

// PUT: Update user by ID
  static String updateUserById(int id) => '$baseUrl/users/$id/update/';

// DELETE: Delete own account
  static const String deleteOwnAccount = '$baseUrl/users/delete/';

//  POST: Upload profile image (if implemented)
  static const String uploadProfileImage = '$baseUrl/users/upload-profile-image/';

  /// POST: Update user device token
  static const String updateDeviceToken = '$baseUrl/users/device-token';

  // GET: Get single contact by ID
  static String getWhatsAppContact = '$baseUrl/get_whatsapp_contact/';

  // UPLOAD PROOFS
  static const String proofs = '$baseUrl/proof_list/'; // For fetching proofs
  static const String uploadProof = '$baseUrl/proofs/'; // For uploading proof

  // transactions
  static const String getTransactions = '$baseUrl/transactions/'; // For fetching transactions

//  STATUS UPDATES
  static String updateProofStatus(int id) => '$baseUrl/proofs/$id/status/';
  static String markProofAsRead(int id) => '$baseUrl/proofs/$id/read/';


  // TRANSACTIONS

  /// GET: All transactions
  static const String transactions = '$baseUrl/transactions';

  /// GET: Transaction by ID / DELETE: Remove transaction
  static String transactionById(int id) => '$baseUrl/transactions/$id';

    /// POST: Mark all messages in a chat as read
  static String markMessagesAsRead(int chatId) => '$baseUrl/chat_message/$chatId/mark-as-read';

  ///search user by contact 
  static const String searchUserByPhone = '$baseUrl/search_contact';


  static String company_info = '$baseUrl/company_info';
  static String agents = '$baseUrl/agents';


  //country
  static String countries = '$baseUrl/countries';

  static String chargeRules = '$baseUrl/charge_rules';


  /// GET: All announcements
  static const String get_announcements = '$baseUrl/announcements';
  /// GET: Create announcements
  static const String create_announcement = '$baseUrl/announcements/';

  /// Edit announcement
  static String edit_announcement(int id) => '$baseUrl/announcements/$id/';
  /// Delete announcement
  static String delete_announcement(int id) => '$baseUrl/announcements/$id/';

  static const String upload_proof_steps = '$baseUrl/upload_proof_steps/';
  static const String password_reset_request = '$baseUrl/password-reset/request/';
  static const String password_reset_confirm = '$baseUrl/password-reset/confirm/';



  /// Handles different path formats from backend
  static String getFullMediaUrl(String? path, {String defaultPath = 'media/default.png'}) {
    if (path == null || path.isEmpty) {
      return '${ApiConstants.publicBaseUrl}/$defaultPath';
    }

    // Case 1: Already a full URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Case 2: Starts with /media/ (common Django format)
    if (path.startsWith('/media/')) {
      return '${ApiConstants.publicBaseUrl}$path';
    }

    // Case 3: Starts with media/ (without leading slash)
    if (path.startsWith('media/')) {
      return '${ApiConstants.publicBaseUrl}/$path';
    }

    // Case 4: Just a filename - assume it's in default media folder
    if (!path.contains('/')) {
      return '${ApiConstants.publicBaseUrl}/media/$path';
    }

    // Case 5: Any other format - just prepend base URL
    return '${ApiConstants.publicBaseUrl}/$path';
  }
  static String getCompanyLogoUrl(
      String? path, {
        String placeholderAsset = 'assets/images/logo_placeholder.png',
      }) {
    if (path == null || path.isEmpty) {
      return placeholderAsset;
    }

    String url = path;

    // Already full URL
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Normalize leading slash
    if (url.startsWith('/')) {
      url = url.substring(1);
    }

    return '$publicBaseUrl/$url';
  }

  /// Handles proof image URLs and placeholders
  static String getProofImageUrl(
      String? path, {
        String placeholder = 'media/proofs/placeholder.png',
      }) {
    if (path == null || path.isEmpty) {
      return '$publicBaseUrl/$placeholder';
    }

    String url = path;

    // Already full URL
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Normalize leading slash
    if (url.startsWith('/')) {
      url = url.substring(1);
    }

    return '$publicBaseUrl/$url';
  }
}
