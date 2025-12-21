import 'package:bilSend/Models/upload_proof_model.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'AuthUser.dart';
import 'ProofStepGuide.dart';
import 'agent.dart';
import 'announcements.dart';
import 'company_info.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bilSend.db');

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE proofs(
      id INTEGER PRIMARY KEY,
      image_url TEXT,
      user_id INTEGER,
      receiver_name TEXT,
      receiver_contact TEXT,
      sender_name TEXT,
      receiver_email TEXT,
      amount TEXT,
      currency TEXT,
      notes TEXT,
      status TEXT,
      status_note TEXT,
      charge_rule INTEGER,       
      charge_amount TEXT,      
      created_at TEXT,
      updated_at TEXT,
      is_read INTEGER DEFAULT 0,
      is_new_for_admin INTEGER DEFAULT 1 
    )
  ''');
    await db.execute('''
  CREATE TABLE company_info(
    id INTEGER PRIMARY KEY,
    type TEXT,
    title TEXT,
    content TEXT,
    icon TEXT,
    color TEXT,
    logo_image TEXT,
    created_at TEXT,
    updated_at TEXT
  )
''');
    await db.execute('''
   CREATE TABLE agents (
   id INTEGER PRIMARY KEY,
   name TEXT,
   account_name TEXT,
   phone TEXT,
   email TEXT,
   logo_image TEXT,
   notes TEXT
          )
        ''');
    await db.execute('''
  CREATE TABLE proof_steps(
    step_number INTEGER PRIMARY KEY,
    title TEXT,
    description TEXT,
    icon TEXT,
    color TEXT
  )
''');

    await db.execute('''
  CREATE TABLE auth_users(
    id INTEGER PRIMARY KEY,
    fullname TEXT,
    email TEXT,
    phone_number TEXT,
    role TEXT,
    location TEXT,
    profile_image TEXT,
    access_token TEXT,
    refresh_token TEXT,
    created_at TEXT,
    updated_at TEXT
  )
''');
    await db.execute('''
  CREATE TABLE announcements (
    id INTEGER PRIMARY KEY,
    title TEXT,
    description TEXT,
    image TEXT,
    image_url TEXT,
    created_by INTEGER,
    is_active INTEGER,
    start_at TEXT,
    end_at TEXT,
    created_at TEXT,
    updated_at TEXT
  )
''');
  }

  Future<void> insertAnnouncementList(List<Announcement> list) async {
    final db = await database;
    final batch = db.batch();

    for (var a in list) {
      batch.insert(
        'announcements',
        {
          'id': a.id,
          'title': a.title,
          'description': a.description,
          'image': a.image,
          'image_url': a.imageUrl,
          'created_by': a.createdBy,
          'is_active': a.isActive ? 1 : 0,
          'start_at': a.startAt?.toIso8601String(),
          'end_at': a.endAt?.toIso8601String(),
          'created_at': a.createdAt.toIso8601String(),
          'updated_at': a.updatedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Insert or update a single user
  Future<int> insertAuthUser(AuthUser user) async {
    final db = await database;
    return await db.insert(
      'auth_users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Announcement>> getLocalAnnouncements() async {
    final db = await database;
    final result = await db.query('announcements', orderBy: "created_at DESC");

    return result.map((json) {
      return Announcement(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        image: json['image'] as String?,
        imageUrl: json['image_url'] as String?,
        createdBy: json['created_by'] as int?,
        isActive: (json['is_active'] as int) == 1,
        startAt: json['start_at'] != null ? DateTime.parse(json['start_at'] as String) : null,
        endAt: json['end_at'] != null ? DateTime.parse(json['end_at'] as String) : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
    }).toList();
  }

  /// Insert or update a list of users
  Future<void> insertAuthUserList(List<AuthUser> users) async {
    final db = await database;
    final batch = db.batch();

    for (var user in users) {
      batch.insert(
        'auth_users',
        user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Fetch all users
  Future<List<AuthUser>> getAllAuthUsers() async {
    final db = await database;
    final result = await db.query('auth_users', orderBy: 'id ASC');
    return result.map((json) => AuthUser.fromMap(json)).toList();
  }

  /// Fetch user by ID
  Future<AuthUser?> getAuthUserById(int id) async {
    final db = await database;
    final result = await db.query('auth_users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return AuthUser.fromMap(result.first);
    }
    return null;
  }

  /// Delete a user by ID
  Future<int> deleteAuthUserById(int id) async {
    final db = await database;
    return await db.delete('auth_users', where: 'id = ?', whereArgs: [id]);
  }

  /// Clear all users
  Future<void> clearAuthUsers() async {
    final db = await database;
    await db.delete('auth_users');
  }

  /// Get user by phone number (for login)
  Future<AuthUser?> getAuthUserByPhone(String phoneNumber) async {
    final db = await database;
    final result = await db.query(
        'auth_users',
        where: 'phone_number = ?',
        whereArgs: [phoneNumber]
    );
    if (result.isNotEmpty) {
      return AuthUser.fromMap(result.first);
    }
    return null;
  }

  /// Insert or update user with conflict handling
  Future<int> insertOrUpdateAuthUser(AuthUser user) async {
    final db = await database;
    return await db.insert(
      'auth_users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get current logged-in user (assuming single user app)
  Future<AuthUser?> getCurrentUser() async {
    final db = await database;
    final result = await db.query('auth_users', limit: 1);
    if (result.isNotEmpty) {
      return AuthUser.fromMap(result.first);
    }
    return null;
  }

  /// Clear all auth data (logout)
  Future<void> clearAuthData() async {
    final db = await database;
    await db.delete('auth_users');
  }
  Future<int> markProofAsRead(int proofId) async {
    final db = await database;
    return await db.update(
      'proofs',
      {'is_read': 1},
      where: 'id = ? AND is_read = 0',
      whereArgs: [proofId],
    );
  }


  Future<int> insertProof(Proof proof) async {
    final db = await database;

    final existing = await db.query(
      'proofs',
      where: 'id = ?',
      whereArgs: [proof.id],
    );

    final data = proof.toJson();

    if (existing.isNotEmpty) {
      final existingData = existing.first;

      // Preserve only fields that should remain local
      data['is_new_for_admin'] = existingData['is_new_for_admin'] ?? 0;
      data['is_read'] = existingData['is_read'] ?? 0;
    } else {
      data['is_new_for_admin'] = 1;
      data['is_read'] = 0;
    }

    return await db.insert(
      'proofs',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<void> insertProofList(List<Proof> proofs) async {
    final db = await database;
    final batch = db.batch();

    for (var proof in proofs) {
      final existing = await db.query(
        'proofs',
        where: 'id = ?',
        whereArgs: [proof.id],
      );

      final data = proof.toJson();

      if (existing.isEmpty) {
        data['is_new_for_admin'] = 1; // mark new for admin
      } else {
        data['is_new_for_admin'] = existing.first['is_new_for_admin'] ?? 0;
      }

      batch.insert(
        'proofs',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Proof>> getAllProofs() async {
    final db = await database;
    final result = await db.query('proofs');
    return result.map((json) => Proof.fromJson(json)).toList();
  }

  Future<int> deleteProofById(int id) async {
    final db = await database;
    return await db.delete('proofs', where: 'id = ?', whereArgs: [id]);
  }
  Future<void> clearProofs() async {
    final db = await database;
    await db.delete('proofs');
  }

  Future<int> updateProof(Proof proof) async {
    final db = await database;
    return await db.update(
      'proofs',
      proof.toJson(), // converts the Proof object to a Map
      where: 'id = ?',
      whereArgs: [proof.id],
    );
  }

  Future<int> getUnreadProofsCount() async {
    final db = await database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM proofs WHERE is_read = 0'),
    );
    return result ?? 0;
  }
  Future<int> getUnreadProofsCountAdmin() async {
    final db = await database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM proofs WHERE is_new_for_admin = 1'),
    );
    return result ?? 0;
  }

  Future<void> markAllProofsAsRead() async {
    final db = await database;
    await db.update('proofs', {'is_read': 1}, where: 'is_read = 0');
  }
  Future<void> markAllProofsAsReadAdmin() async {
    final db = await database;
    await db.update('proofs', {'is_new_for_admin': 0}, where: 'is_new_for_admin = 1');
  }
  Future<int> markProofAsSeenByAdmin(int proofId) async {
    final db = await database;
    return await db.update(
      'proofs',
      {'is_new_for_admin': 0},
      where: 'id = ?',
      whereArgs: [proofId],
    );
  }

  // Save single company info
  Future<void> insertCompanyInfo(CompanyInfo info) async {
    final db = await database;
    await db.insert(
      'company_info',
      info.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Save a list of company info (batch)
  Future<void> insertCompanyInfoList(List<CompanyInfo> infoList) async {
    final db = await database;
    final batch = db.batch();
    for (var info in infoList) {
      batch.insert(
        'company_info',
        info.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Fetch all company info
  Future<List<CompanyInfo>> getAllCompanyInfo() async {
    final db = await database;
    final maps = await db.query('company_info', orderBy: 'id ASC');
    return maps.map((json) => CompanyInfo.fromJson(json)).toList();
  }

  Future<void> clearCompanyInfo() async {
    final db = await database;
    await db.delete('company_info');
  }

  /// ================== AGENT TABLE ==================

  Future<void> insertAgentList(List<Agent> agents) async {
    final db = await database;
    final batch = db.batch();

    for (var agent in agents) {
      batch.insert(
        'agents',
        {
          'id': agent.id,
          'name': agent.name,
          'account_name': agent.accountName,
          'phone': agent.phone,
          'email': agent.email,
          'logo_image': agent.logoImage,
          'notes': agent.notes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Agent>> getAllAgents() async {
    final db = await database;
    final result = await db.query('agents');
    return result.map((json) => Agent.fromJson(json)).toList();
  }

  Future<void> clearAgents() async {
    final db = await database;
    await db.delete('agents');
  }

  Future<void> insertProofStep(ProofStep step) async {
    final db = await database;
    await db.insert(
      'proof_steps',
      step.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertProofStepsList(List<ProofStep> steps) async {
    final db = await database;
    final batch = db.batch();

    for (var step in steps) {
      batch.insert(
        'proof_steps',
        step.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<ProofStep>> getAllProofSteps() async {
    final db = await database;
    final maps = await db.query(
      'proof_steps',
      orderBy: 'step_number ASC',
    );
    return maps.map((json) => ProofStep.fromJson(json)).toList();
  }

  Future<void> clearProofSteps() async {
    final db = await database;
    await db.delete('proof_steps');
  }


}
