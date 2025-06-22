import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/agent.dart';
import '../models/parcel.dart';
import 'sms_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final NotificationService _notificationService = NotificationService();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(
      path.join(dbPath, 'zipbus.db'),
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE agents (
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            mobile TEXT,
            profilePicture TEXT,
            isAdmin INTEGER,
            isFrozen INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE parcels (
            id TEXT PRIMARY KEY,
            senderName TEXT,
            senderPhone TEXT,
            receiverName TEXT,
            receiverPhone TEXT,
            fromLocation TEXT,
            toLocation TEXT,
            amount REAL,
            status TEXT,
            trackingNumber TEXT UNIQUE,
            createdBy TEXT,
            createdAt TEXT,
            receivedBy TEXT,
            deliveredBy TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE activities (
            id TEXT PRIMARY KEY,
            time TEXT,
            user_id TEXT,
            action TEXT
          )
        ''');
        await db.insert('agents', {
          'id': '1',
          'name': 'Admin User',
          'email': 'admin@zipbus2.com',
          'password': 'admin123',
          'mobile': '1234567890',
          'profilePicture': null,
          'isAdmin': 1,
          'isFrozen': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 7) {
          await db.execute('ALTER TABLE parcels ADD COLUMN receivedBy TEXT');
          await db.execute('ALTER TABLE parcels ADD COLUMN deliveredBy TEXT');
        }
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE activities (
              id TEXT PRIMARY KEY,
              time TEXT,
              user_id TEXT,
              action TEXT
            )
          ''');
        }
      },
    );
  }

  Future<Agent?> getAgentByEmail(String email) async {
    final db = await _db;
    final result = await db.query(
      'agents',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? Agent.fromMap(result.first) : null;
  }

  Future<Agent?> getAgentById(String id) async {
    final db = await _db;
    final result = await db.query(
      'agents',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Agent.fromMap(result.first) : null;
  }

  Future<void> insertParcel(Parcel parcel) async {
    final db = await _db;
    await db.insert('parcels', parcel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    // Log activity
    await _logActivity('Inserted parcel #${parcel.trackingNumber}', parcel.createdBy);
    // Send simple notifications for parcel creation
    await _notificationService.sendStatusUpdateNotification(
      phoneNumber: parcel.senderPhone,
      trackingNumber: parcel.trackingNumber,
      status: 'Pending',
    );
    await _notificationService.sendStatusUpdateNotification(
      phoneNumber: parcel.receiverPhone,
      trackingNumber: parcel.trackingNumber,
      status: 'Pending',
    );
  }

  Future<void> updateParcel(Parcel parcel) async {
    final db = await _db;
    final oldParcel = await getParcelById(parcel.id);
    await db.update('parcels', parcel.toMap(),
        where: 'id = ?', whereArgs: [parcel.id]);
    
    // Log activity
    await _logActivity('Updated parcel #${parcel.trackingNumber} to status ${parcel.status}', parcel.createdBy);
    
    // Send simple notifications based on status
    if (parcel.status == 'In Transit' && oldParcel?.status != 'In Transit') {
      if (parcel.senderPhone.isNotEmpty) {
        await _notificationService.sendStatusUpdateNotification(
          phoneNumber: parcel.senderPhone,
          trackingNumber: parcel.trackingNumber,
          status: 'In Transit',
        );
      }
      if (parcel.receiverPhone.isNotEmpty) {
        await _notificationService.sendStatusUpdateNotification(
          phoneNumber: parcel.receiverPhone,
          trackingNumber: parcel.trackingNumber,
          status: 'In Transit',
        );
      }
    } else if (parcel.status == 'Delivered' && oldParcel?.status != 'Delivered') {
      if (parcel.senderPhone.isNotEmpty) {
        await _notificationService.sendStatusUpdateNotification(
          phoneNumber: parcel.senderPhone,
          trackingNumber: parcel.trackingNumber,
          status: 'Delivered',
        );
      }
      if (parcel.receiverPhone.isNotEmpty) {
        await _notificationService.sendStatusUpdateNotification(
          phoneNumber: parcel.receiverPhone,
          trackingNumber: parcel.trackingNumber,
          status: 'Delivered',
        );
      }
    }
  }

  Future<Parcel?> getParcelById(String id) async {
    final db = await _db;
    final result = await db.query(
      'parcels',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Parcel.fromMap(result.first) : null;
  }

  Future<Parcel?> getParcelByTrackingNumber(String trackingNumber) async {
    final db = await _db;
    final result = await db.query(
      'parcels',
      where: 'trackingNumber = ?',
      whereArgs: [trackingNumber],
    );
    return result.isNotEmpty ? Parcel.fromMap(result.first) : null;
  }

  Future<List<Parcel>> getParcelsByAgent(String agentId) async {
    final db = await _db;
    final result = await db.query(
      'parcels',
      where: 'createdBy = ?',
      whereArgs: [agentId],
    );
    return result.map((map) => Parcel.fromMap(map)).toList();
  }

  Future<void> updateAgent(Agent agent) async {
    final db = await _db;
    await db.update('agents', agent.toMap(),
        where: 'id = ?', whereArgs: [agent.id]);
    await _logActivity('Updated agent profile for ${agent.name}', agent.id);
  }

  Future<List<Agent>> getAllAgents() async {
    final db = await _db;
    final result = await db.query('agents');
    return result.map((map) => Agent.fromMap(map)).toList();
  }

  Future<void> deleteAgent(String agentId) async {
    final db = await _db;
    final agent = await getAgentById(agentId);
    await db.delete('agents', where: 'id = ?', whereArgs: [agentId]);
    if (agent != null) {
      await _logActivity('Deleted agent ${agent.name}', agentId);
    }
  }

  Future<void> insertAgent(Agent agent) async {
    final db = await _db;
    await db.insert('agents', agent.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await _logActivity('Inserted new agent ${agent.name}', agent.id);
  }

  Future<Database> get database async => await _db;

  Future<int> getPendingParcelsCount() async {
    final db = await _db;
    final result = await db.query(
      'parcels',
      where: 'status = ? AND receivedBy IS NULL',
      whereArgs: ['Pending'],
    );
    return result.length;
  }

  Future<int> getInTransitParcelsCount() async {
    final db = await _db;
    final result = await db.query(
      'parcels',
      where: 'status = ?',
      whereArgs: ['In Transit'],
    );
    return result.length;
  }

  Future<int> getDeliveredParcelsCount() async {
    final db = await _db;
    final result = await db.query(
      'parcels',
      where: 'status = ?',
      whereArgs: ['Delivered'],
    );
    return result.length;
  }

  User getCurrentUser() {
    return User(id: 'current_user_id', isAdmin: true);
  }

  Future<void> updateAgentProfilePicture(String agentId, String imagePath) async {
    final db = await _db;
    try {
      await db.update(
        'agents',
        {'profilePicture': imagePath},
        where: 'id = ?',
        whereArgs: [agentId],
      );
      await _logActivity('Updated profile picture for agent', agentId);
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }

  Future<void> _logActivity(String action, String userId) async {
    final db = await _db;
    final timestamp = DateTime.now().toIso8601String();
    final id = '${timestamp}_$userId';
    await db.insert(
      'activities',
      {
        'id': id,
        'time': timestamp,
        'user_id': userId,
        'action': action,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, String>>> getActivities() async {
    final db = await _db;
    final result = await db.query('activities', orderBy: 'time DESC');
    return result.map((map) {
      return {
        'id': map['id'] as String,
        'time': map['time'] as String,
        'user_id': map['user_id'] as String,
        'action': map['action'] as String,
      };
    }).toList();
  }


}

class User {
  final String id;
  final bool isAdmin;

  User({required this.id, required this.isAdmin});
}
