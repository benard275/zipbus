import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/agent.dart';
import '../models/parcel.dart';
import '../models/payment_record.dart';
import '../models/customer_analytics.dart';
import '../models/invoice.dart';
import '../models/message.dart';
import '../models/conversation.dart';
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
      version: 14,
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
            deliveredBy TEXT,
            paymentMethod TEXT DEFAULT 'cash',
            paymentStatus TEXT DEFAULT 'pending',
            paymentReference TEXT,
            preferredDeliveryDate TEXT,
            preferredDeliveryTime TEXT,
            deliveryInstructions TEXT,
            pickupPhotoPath TEXT,
            deliveryPhotoPath TEXT,
            signaturePath TEXT,
            hasInsurance INTEGER DEFAULT 0,
            insuranceValue REAL,
            insurancePremium REAL,
            specialHandling TEXT,
            declaredValue REAL
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
        await db.execute('''
          CREATE TABLE payment_records (
            id TEXT PRIMARY KEY,
            trackingNumber TEXT,
            fromLocation TEXT,
            toLocation TEXT,
            amount REAL,
            paymentDate TEXT,
            agentId TEXT,
            agentName TEXT,
            paymentMethod TEXT,
            paymentReference TEXT,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE customer_analytics (
            id TEXT PRIMARY KEY,
            customerPhone TEXT,
            customerName TEXT,
            totalParcels INTEGER,
            totalSpent REAL,
            firstParcelDate TEXT,
            lastParcelDate TEXT,
            averageParcelValue REAL,
            frequentRoutes TEXT,
            satisfactionScore REAL,
            satisfactionRatingsCount INTEGER,
            customerTier TEXT,
            isRepeatCustomer INTEGER,
            monthsActive INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE satisfaction_ratings (
            id TEXT PRIMARY KEY,
            parcelId TEXT,
            trackingNumber TEXT,
            customerPhone TEXT,
            rating INTEGER,
            feedback TEXT,
            createdAt TEXT,
            ratingType TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE invoices (
            id TEXT PRIMARY KEY,
            invoiceNumber TEXT UNIQUE,
            parcelId TEXT,
            trackingNumber TEXT,
            customerName TEXT,
            customerPhone TEXT,
            customerEmail TEXT,
            invoiceDate TEXT,
            dueDate TEXT,
            subtotal REAL,
            insuranceFee REAL,
            specialHandlingFee REAL,
            taxAmount REAL,
            totalAmount REAL,
            status TEXT,
            pdfPath TEXT,
            createdAt TEXT,
            createdBy TEXT,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE invoice_line_items (
            id TEXT PRIMARY KEY,
            invoiceId TEXT,
            description TEXT,
            quantity INTEGER,
            unitPrice REAL,
            totalPrice REAL,
            itemType TEXT
          )
        ''');

        // Chat system tables
        await db.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            participant1Id TEXT,
            participant1Name TEXT,
            participant2Id TEXT,
            participant2Name TEXT,
            lastMessageId TEXT,
            lastMessageText TEXT,
            lastMessageTime TEXT,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversationId TEXT,
            senderId TEXT,
            senderName TEXT,
            receiverId TEXT,
            receiverName TEXT,
            messageText TEXT,
            messageType TEXT DEFAULT 'text',
            isRead INTEGER DEFAULT 0,
            sentAt TEXT,
            deliveredAt TEXT,
            readAt TEXT,
            deliveryStatus TEXT DEFAULT 'sent'
          )
        ''');
        await db.execute('''
          CREATE TABLE financial_reports (
            id TEXT PRIMARY KEY,
            reportDate TEXT,
            reportType TEXT,
            startDate TEXT,
            endDate TEXT,
            totalRevenue REAL,
            totalExpenses REAL,
            netProfit REAL,
            grossProfit REAL,
            totalParcels INTEGER,
            averageParcelValue REAL,
            revenueByCategory TEXT,
            expensesByCategory TEXT,
            parcelsByStatus TEXT,
            taxCollected REAL,
            insuranceRevenue REAL,
            specialHandlingRevenue REAL
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
        if (oldVersion < 9) {
          // Add new payment and delivery fields
          await db.execute('ALTER TABLE parcels ADD COLUMN paymentMethod TEXT DEFAULT "cash"');
          await db.execute('ALTER TABLE parcels ADD COLUMN paymentStatus TEXT DEFAULT "pending"');
          await db.execute('ALTER TABLE parcels ADD COLUMN paymentReference TEXT');
          await db.execute('ALTER TABLE parcels ADD COLUMN preferredDeliveryDate TEXT');
          await db.execute('ALTER TABLE parcels ADD COLUMN preferredDeliveryTime TEXT');
          await db.execute('ALTER TABLE parcels ADD COLUMN deliveryInstructions TEXT');
          await db.execute('ALTER TABLE parcels ADD COLUMN pickupPhotoPath TEXT');
          await db.execute('ALTER TABLE parcels ADD COLUMN deliveryPhotoPath TEXT');
          await db.execute('ALTER TABLE parcels ADD COLUMN signaturePath TEXT');
        }
        if (oldVersion < 10) {
          // Ensure delivery schedule fields exist and are properly configured
          await _ensureDeliveryScheduleFields(db);
        }
        if (oldVersion < 11) {
          // Add payment records table for admin tracking
          await db.execute('''
            CREATE TABLE payment_records (
              id TEXT PRIMARY KEY,
              trackingNumber TEXT,
              fromLocation TEXT,
              toLocation TEXT,
              amount REAL,
              paymentDate TEXT,
              agentId TEXT,
              agentName TEXT,
              paymentMethod TEXT,
              paymentReference TEXT,
              createdAt TEXT
            )
          ''');
        }
        if (oldVersion < 12) {
          // Add smart parcel features to parcels table
          await db.execute('ALTER TABLE parcels ADD COLUMN hasInsurance INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE parcels ADD COLUMN insuranceValue REAL');
          await db.execute('ALTER TABLE parcels ADD COLUMN insurancePremium REAL');
          await db.execute('ALTER TABLE parcels ADD COLUMN specialHandling TEXT');
          await db.execute('ALTER TABLE parcels ADD COLUMN declaredValue REAL');

          // Add customer analytics table
          await db.execute('''
            CREATE TABLE customer_analytics (
              id TEXT PRIMARY KEY,
              customerPhone TEXT,
              customerName TEXT,
              totalParcels INTEGER,
              totalSpent REAL,
              firstParcelDate TEXT,
              lastParcelDate TEXT,
              averageParcelValue REAL,
              frequentRoutes TEXT,
              satisfactionScore REAL,
              satisfactionRatingsCount INTEGER,
              customerTier TEXT,
              isRepeatCustomer INTEGER,
              monthsActive INTEGER
            )
          ''');

          // Add satisfaction ratings table
          await db.execute('''
            CREATE TABLE satisfaction_ratings (
              id TEXT PRIMARY KEY,
              parcelId TEXT,
              trackingNumber TEXT,
              customerPhone TEXT,
              rating INTEGER,
              feedback TEXT,
              createdAt TEXT,
              ratingType TEXT
            )
          ''');

          // Add invoices table
          await db.execute('''
            CREATE TABLE invoices (
              id TEXT PRIMARY KEY,
              invoiceNumber TEXT UNIQUE,
              parcelId TEXT,
              trackingNumber TEXT,
              customerName TEXT,
              customerPhone TEXT,
              customerEmail TEXT,
              invoiceDate TEXT,
              dueDate TEXT,
              subtotal REAL,
              insuranceFee REAL,
              specialHandlingFee REAL,
              taxAmount REAL,
              totalAmount REAL,
              status TEXT,
              pdfPath TEXT,
              createdAt TEXT,
              createdBy TEXT,
              notes TEXT
            )
          ''');

          // Add invoice line items table
          await db.execute('''
            CREATE TABLE invoice_line_items (
              id TEXT PRIMARY KEY,
              invoiceId TEXT,
              description TEXT,
              quantity INTEGER,
              unitPrice REAL,
              totalPrice REAL,
              itemType TEXT
            )
          ''');

          // Add financial reports table
          await db.execute('''
            CREATE TABLE financial_reports (
              id TEXT PRIMARY KEY,
              reportDate TEXT,
              reportType TEXT,
              startDate TEXT,
              endDate TEXT,
              totalRevenue REAL,
              totalExpenses REAL,
              netProfit REAL,
              grossProfit REAL,
              totalParcels INTEGER,
              averageParcelValue REAL,
              revenueByCategory TEXT,
              expensesByCategory TEXT,
              parcelsByStatus TEXT,
              taxCollected REAL,
              insuranceRevenue REAL,
              specialHandlingRevenue REAL
            )
          ''');
        }

        // Version 13: Add chat system tables
        if (oldVersion < 13) {
          await db.execute('''
            CREATE TABLE conversations (
              id TEXT PRIMARY KEY,
              participant1Id TEXT,
              participant1Name TEXT,
              participant2Id TEXT,
              participant2Name TEXT,
              lastMessageId TEXT,
              lastMessageText TEXT,
              lastMessageTime TEXT,
              createdAt TEXT,
              updatedAt TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE messages (
              id TEXT PRIMARY KEY,
              conversationId TEXT,
              senderId TEXT,
              senderName TEXT,
              receiverId TEXT,
              receiverName TEXT,
              messageText TEXT,
              messageType TEXT DEFAULT 'text',
              isRead INTEGER DEFAULT 0,
              sentAt TEXT,
              deliveredAt TEXT,
              readAt TEXT,
              deliveryStatus TEXT DEFAULT 'sent'
            )
          ''');
        }

        // Version 14: Add delivery status fields to messages
        if (oldVersion < 14) {
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN deliveredAt TEXT');
            debugPrint('✅ Added deliveredAt field to messages table');
          } catch (e) {
            debugPrint('ℹ️ deliveredAt field already exists or error: $e');
          }

          try {
            await db.execute('ALTER TABLE messages ADD COLUMN deliveryStatus TEXT DEFAULT "sent"');
            debugPrint('✅ Added deliveryStatus field to messages table');
          } catch (e) {
            debugPrint('ℹ️ deliveryStatus field already exists or error: $e');
          }

          // Update existing messages to have 'delivered' status since they're already in the database
          try {
            await db.execute('UPDATE messages SET deliveryStatus = "delivered" WHERE deliveryStatus IS NULL');
            debugPrint('✅ Updated existing messages delivery status');
          } catch (e) {
            debugPrint('ℹ️ Error updating existing messages: $e');
          }
        }
      },
    );
  }

  /// Ensure delivery schedule fields exist in the database
  Future<void> _ensureDeliveryScheduleFields(Database db) async {
    try {
      // Check if delivery schedule fields exist by trying to query them
      await db.rawQuery('SELECT preferredDeliveryDate, preferredDeliveryTime, deliveryInstructions FROM parcels LIMIT 1');
      debugPrint('✅ Delivery schedule fields already exist');
    } catch (e) {
      debugPrint('⚠️ Delivery schedule fields missing, adding them...');
      try {
        // Add delivery schedule fields if they don't exist
        await db.execute('ALTER TABLE parcels ADD COLUMN preferredDeliveryDate TEXT');
        debugPrint('✅ Added preferredDeliveryDate field');
      } catch (e) {
        debugPrint('ℹ️ preferredDeliveryDate field already exists or error: $e');
      }

      try {
        await db.execute('ALTER TABLE parcels ADD COLUMN preferredDeliveryTime TEXT');
        debugPrint('✅ Added preferredDeliveryTime field');
      } catch (e) {
        debugPrint('ℹ️ preferredDeliveryTime field already exists or error: $e');
      }

      try {
        await db.execute('ALTER TABLE parcels ADD COLUMN deliveryInstructions TEXT');
        debugPrint('✅ Added deliveryInstructions field');
      } catch (e) {
        debugPrint('ℹ️ deliveryInstructions field already exists or error: $e');
      }
    }
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

    // Debug: Log delivery schedule data being saved
    final parcelMap = parcel.toMap();
    debugPrint('🔍 Inserting parcel with delivery schedule:');
    debugPrint('   Tracking: ${parcel.trackingNumber}');
    debugPrint('   Preferred Date: ${parcelMap['preferredDeliveryDate']}');
    debugPrint('   Preferred Time: ${parcelMap['preferredDeliveryTime']}');
    debugPrint('   Instructions: ${parcelMap['deliveryInstructions']}');

    await db.insert('parcels', parcelMap, conflictAlgorithm: ConflictAlgorithm.replace);

    // Verify the data was saved correctly
    final savedParcel = await getParcelByTrackingNumber(parcel.trackingNumber);
    if (savedParcel != null) {
      debugPrint('✅ Parcel saved successfully with delivery schedule:');
      debugPrint('   Saved Date: ${savedParcel.preferredDeliveryDate}');
      debugPrint('   Saved Time: ${savedParcel.preferredDeliveryTime}');
      debugPrint('   Saved Instructions: ${savedParcel.deliveryInstructions}');
    } else {
      debugPrint('❌ Failed to verify saved parcel');
    }

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
    } else if (parcel.status == 'Cancelled' && oldParcel?.status != 'Cancelled') {
      if (parcel.senderPhone.isNotEmpty) {
        await _notificationService.sendStatusUpdateNotification(
          phoneNumber: parcel.senderPhone,
          trackingNumber: parcel.trackingNumber,
          status: 'Cancelled',
        );
      }
      if (parcel.receiverPhone.isNotEmpty) {
        await _notificationService.sendStatusUpdateNotification(
          phoneNumber: parcel.receiverPhone,
          trackingNumber: parcel.trackingNumber,
          status: 'Cancelled',
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

  Future<List<Parcel>> getAllParcels() async {
    final db = await _db;
    final result = await db.query('parcels');
    return result.map((map) => Parcel.fromMap(map)).toList();
  }

  Future<List<Agent>> getAllAgents() async {
    final db = await _db;
    final result = await db.query('agents');
    return result.map((map) => Agent.fromMap(map)).toList();
  }

  Future<void> updateAgent(Agent agent) async {
    final db = await _db;
    await db.update('agents', agent.toMap(),
        where: 'id = ?', whereArgs: [agent.id]);
    await _logActivity('Updated agent profile for ${agent.name}', agent.id);
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

  Future<int> getCancelledParcelsCount() async {
    final db = await _db;
    final result = await db.query(
      'parcels',
      where: 'status = ?',
      whereArgs: ['Cancelled'],
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

  Future<void> removeAgentProfilePicture(String agentId) async {
    final db = await _db;
    try {
      await db.update(
        'agents',
        {'profilePicture': null},
        where: 'id = ?',
        whereArgs: [agentId],
      );
      await _logActivity('Removed profile picture for agent', agentId);
    } catch (e) {
      throw Exception('Failed to remove profile picture: $e');
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

  /// Debug method to check delivery schedule data in database
  Future<void> debugDeliverySchedules() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT trackingNumber, preferredDeliveryDate, preferredDeliveryTime, deliveryInstructions
        FROM parcels
        WHERE preferredDeliveryDate IS NOT NULL OR preferredDeliveryTime IS NOT NULL OR deliveryInstructions IS NOT NULL
        ORDER BY createdAt DESC
        LIMIT 10
      ''');

      debugPrint('📋 Recent parcels with delivery schedules:');
      if (result.isEmpty) {
        debugPrint('   No parcels found with delivery schedule data');
      } else {
        for (final row in result) {
          debugPrint('   Tracking: ${row['trackingNumber']}');
          debugPrint('     Date: ${row['preferredDeliveryDate'] ?? 'Not set'}');
          debugPrint('     Time: ${row['preferredDeliveryTime'] ?? 'Not set'}');
          debugPrint('     Instructions: ${row['deliveryInstructions'] ?? 'Not set'}');
          debugPrint('   ---');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking delivery schedules: $e');
    }
  }

  /// Get parcels with delivery schedules for reporting
  Future<List<Parcel>> getParcelsWithDeliverySchedules() async {
    final db = await _db;
    final result = await db.query(
      'parcels',
      where: 'preferredDeliveryDate IS NOT NULL OR preferredDeliveryTime IS NOT NULL OR deliveryInstructions IS NOT NULL',
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Parcel.fromMap(map)).toList();
  }

  /// Mark payment as paid and record payment transaction (IRREVERSIBLE)
  Future<bool> markPaymentAsPaid({
    required String parcelId,
    required String agentId,
    required String agentName,
  }) async {
    try {
      // Get the parcel first
      final parcel = await getParcelById(parcelId);
      if (parcel == null) {
        debugPrint('❌ Parcel not found: $parcelId');
        return false;
      }

      // Check if payment is already paid (prevent double payment)
      if (parcel.paymentStatus == 'paid') {
        debugPrint('⚠️ Payment already marked as paid for parcel: ${parcel.trackingNumber}');
        return false;
      }

      // Update parcel payment status to 'paid' (IRREVERSIBLE)
      final updatedParcel = Parcel(
        id: parcel.id,
        senderName: parcel.senderName,
        senderPhone: parcel.senderPhone,
        receiverName: parcel.receiverName,
        receiverPhone: parcel.receiverPhone,
        fromLocation: parcel.fromLocation,
        toLocation: parcel.toLocation,
        amount: parcel.amount,
        status: parcel.status,
        trackingNumber: parcel.trackingNumber,
        createdBy: parcel.createdBy,
        createdAt: parcel.createdAt,
        receivedBy: parcel.receivedBy,
        deliveredBy: parcel.deliveredBy,
        paymentMethod: parcel.paymentMethod,
        paymentStatus: 'paid', // IRREVERSIBLE CHANGE
        paymentReference: parcel.paymentReference,
        preferredDeliveryDate: parcel.preferredDeliveryDate,
        preferredDeliveryTime: parcel.preferredDeliveryTime,
        deliveryInstructions: parcel.deliveryInstructions,
        pickupPhotoPath: parcel.pickupPhotoPath,
        deliveryPhotoPath: parcel.deliveryPhotoPath,
        signaturePath: parcel.signaturePath,
        // Smart parcel features
        hasInsurance: parcel.hasInsurance,
        insuranceValue: parcel.insuranceValue,
        insurancePremium: parcel.insurancePremium,
        specialHandling: parcel.specialHandling,
        declaredValue: parcel.declaredValue,
      );

      await updateParcel(updatedParcel);

      // Create payment record for admin tracking
      final paymentRecord = PaymentRecord(
        id: const Uuid().v4(),
        trackingNumber: parcel.trackingNumber,
        fromLocation: parcel.fromLocation,
        toLocation: parcel.toLocation,
        amount: parcel.amount,
        paymentDate: DateTime.now().toIso8601String(),
        agentId: agentId,
        agentName: agentName,
        paymentMethod: parcel.paymentMethod,
        paymentReference: parcel.paymentReference,
        createdAt: DateTime.now().toIso8601String(),
      );

      await insertPaymentRecord(paymentRecord);

      // Log activity
      await _logActivity('Marked payment as PAID for parcel #${parcel.trackingNumber} - Amount: TZS ${parcel.amount}', agentId);

      debugPrint('✅ Payment marked as paid for parcel: ${parcel.trackingNumber}');
      debugPrint('   Amount: TZS ${parcel.amount}');
      debugPrint('   Agent: $agentName');
      debugPrint('   Method: ${parcel.paymentMethod}');

      return true;
    } catch (e) {
      debugPrint('❌ Error marking payment as paid: $e');
      return false;
    }
  }

  /// Insert payment record for admin tracking
  Future<void> insertPaymentRecord(PaymentRecord paymentRecord) async {
    final db = await _db;
    await db.insert('payment_records', paymentRecord.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('💰 Payment record created: ${paymentRecord.trackingNumber}');
  }

  /// Get all payment records (admin only)
  Future<List<PaymentRecord>> getAllPaymentRecords() async {
    final db = await _db;
    final result = await db.query('payment_records', orderBy: 'paymentDate DESC');
    return result.map((map) => PaymentRecord.fromMap(map)).toList();
  }

  /// Get payment records by date range
  Future<List<PaymentRecord>> getPaymentRecordsByDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'paymentDate >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'paymentDate <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.query(
      'payment_records',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'paymentDate DESC',
    );

    return result.map((map) => PaymentRecord.fromMap(map)).toList();
  }

  /// Get payment records by agent
  Future<List<PaymentRecord>> getPaymentRecordsByAgent(String agentId) async {
    final db = await _db;
    final result = await db.query(
      'payment_records',
      where: 'agentId = ?',
      whereArgs: [agentId],
      orderBy: 'paymentDate DESC',
    );
    return result.map((map) => PaymentRecord.fromMap(map)).toList();
  }

  /// Get payment statistics
  Future<Map<String, dynamic>> getPaymentStatistics() async {
    final db = await _db;

    // Total payments
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count, SUM(amount) as total FROM payment_records');
    final totalPayments = totalResult.first['count'] as int;
    final totalAmount = (totalResult.first['total'] as double?) ?? 0.0;

    // Payments by method
    final methodResult = await db.rawQuery('''
      SELECT paymentMethod, COUNT(*) as count, SUM(amount) as total
      FROM payment_records
      GROUP BY paymentMethod
    ''');

    // Payments by agent
    final agentResult = await db.rawQuery('''
      SELECT agentName, COUNT(*) as count, SUM(amount) as total
      FROM payment_records
      GROUP BY agentId, agentName
      ORDER BY total DESC
    ''');

    return {
      'totalPayments': totalPayments,
      'totalAmount': totalAmount,
      'paymentsByMethod': methodResult,
      'paymentsByAgent': agentResult,
    };
  }

  /// Get customer behavior analytics
  Future<Map<String, dynamic>> getCustomerBehaviorAnalytics() async {
    final db = await _db;

    // Get repeat customers
    final repeatCustomersResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM (
        SELECT senderPhone, COUNT(*) as parcelCount
        FROM parcels
        GROUP BY senderPhone
        HAVING parcelCount > 1
      )
    ''');
    final repeatCustomers = repeatCustomersResult.first['count'] as int;

    // Get total unique customers
    final totalCustomersResult = await db.rawQuery('SELECT COUNT(DISTINCT senderPhone) as count FROM parcels');
    final totalCustomers = totalCustomersResult.first['count'] as int;

    // Get average parcels per customer
    final avgParcelsResult = await db.rawQuery('''
      SELECT AVG(parcelCount) as avgParcels
      FROM (
        SELECT senderPhone, COUNT(*) as parcelCount
        FROM parcels
        GROUP BY senderPhone
      )
    ''');
    final avgParcelsPerCustomer = avgParcelsResult.isNotEmpty && avgParcelsResult.first['avgParcels'] != null
        ? (avgParcelsResult.first['avgParcels'] as num).toDouble()
        : 0.0;

    // Get customer lifetime value
    final clvResult = await db.rawQuery('''
      SELECT AVG(totalSpent) as avgClv
      FROM (
        SELECT senderPhone, SUM(amount) as totalSpent
        FROM parcels
        GROUP BY senderPhone
      )
    ''');
    final avgCustomerLifetimeValue = clvResult.isNotEmpty && clvResult.first['avgClv'] != null
        ? (clvResult.first['avgClv'] as num).toDouble()
        : 0.0;

    // Get most popular routes
    final popularRoutesResult = await db.rawQuery('''
      SELECT
        (fromLocation || ' → ' || toLocation) as route,
        COUNT(*) as count,
        SUM(amount) as revenue
      FROM parcels
      GROUP BY fromLocation, toLocation
      ORDER BY count DESC
      LIMIT 5
    ''');

    return {
      'totalCustomers': totalCustomers,
      'repeatCustomers': repeatCustomers,
      'retentionRate': totalCustomers > 0 ? (repeatCustomers / totalCustomers) * 100 : 0.0,
      'avgParcelsPerCustomer': avgParcelsPerCustomer,
      'avgCustomerLifetimeValue': avgCustomerLifetimeValue,
      'popularRoutes': popularRoutesResult,
    };
  }

  /// Get business performance metrics
  Future<Map<String, dynamic>> getBusinessPerformanceMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    final start = startDate?.toIso8601String() ?? DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final end = endDate?.toIso8601String() ?? DateTime.now().toIso8601String();

    // Revenue growth
    final revenueResult = await db.rawQuery('''
      SELECT SUM(amount) as revenue
      FROM parcels
      WHERE createdAt >= ? AND createdAt <= ?
    ''', [start, end]);
    final currentRevenue = revenueResult.isNotEmpty && revenueResult.first['revenue'] != null
        ? (revenueResult.first['revenue'] as num).toDouble()
        : 0.0;

    // Previous period revenue for comparison
    final defaultStart = DateTime.now().subtract(const Duration(days: 30));
    final defaultEnd = DateTime.now();
    final actualStart = startDate ?? defaultStart;
    final actualEnd = endDate ?? defaultEnd;
    final periodDays = actualEnd.difference(actualStart).inDays;

    final previousStart = actualStart.subtract(Duration(days: periodDays));
    final previousEnd = actualStart;

    final previousRevenueResult = await db.rawQuery('''
      SELECT SUM(amount) as revenue
      FROM parcels
      WHERE createdAt >= ? AND createdAt <= ?
    ''', [previousStart.toIso8601String(), previousEnd.toIso8601String()]);
    final previousRevenue = previousRevenueResult.isNotEmpty && previousRevenueResult.first['revenue'] != null
        ? (previousRevenueResult.first['revenue'] as num).toDouble()
        : 0.0;

    final revenueGrowth = previousRevenue > 0 ? ((currentRevenue - previousRevenue) / previousRevenue) * 100 : 0.0;

    // Parcel volume growth
    final volumeResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM parcels
      WHERE createdAt >= ? AND createdAt <= ?
    ''', [start, end]);
    final currentVolume = volumeResult.first['count'] as int;

    final previousVolumeResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM parcels
      WHERE createdAt >= ? AND createdAt <= ?
    ''', [previousStart.toIso8601String(), previousEnd.toIso8601String()]);
    final previousVolume = previousVolumeResult.first['count'] as int;

    final volumeGrowth = previousVolume > 0 ? ((currentVolume - previousVolume) / previousVolume) * 100 : 0.0;

    // Delivery success rate
    final deliveredResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM parcels
      WHERE status = 'Delivered' AND createdAt >= ? AND createdAt <= ?
    ''', [start, end]);
    final deliveredCount = deliveredResult.first['count'] as int;

    final deliverySuccessRate = currentVolume > 0 ? (deliveredCount / currentVolume) * 100 : 0.0;

    // Average delivery time (for delivered parcels)
    final avgDeliveryTimeResult = await db.rawQuery('''
      SELECT AVG(julianday(updatedAt) - julianday(createdAt)) as avgDays
      FROM parcels
      WHERE status = 'Delivered' AND createdAt >= ? AND createdAt <= ?
    ''', [start, end]);
    final avgDeliveryTime = avgDeliveryTimeResult.isNotEmpty && avgDeliveryTimeResult.first['avgDays'] != null
        ? (avgDeliveryTimeResult.first['avgDays'] as num).toDouble()
        : 0.0;

    return {
      'currentRevenue': currentRevenue,
      'previousRevenue': previousRevenue,
      'revenueGrowth': revenueGrowth,
      'currentVolume': currentVolume,
      'previousVolume': previousVolume,
      'volumeGrowth': volumeGrowth,
      'deliverySuccessRate': deliverySuccessRate,
      'avgDeliveryTime': avgDeliveryTime,
    };
  }

  /// Get agent performance analytics
  Future<List<Map<String, dynamic>>> getAgentPerformanceAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    final start = startDate?.toIso8601String() ?? DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final end = endDate?.toIso8601String() ?? DateTime.now().toIso8601String();

    final result = await db.rawQuery('''
      SELECT
        a.id,
        a.name,
        a.email,
        COUNT(p.id) as parcelsHandled,
        SUM(p.amount) as revenueGenerated,
        AVG(p.amount) as avgParcelValue,
        COUNT(CASE WHEN p.status = 'Delivered' THEN 1 END) as deliveredParcels,
        COUNT(CASE WHEN p.status = 'Cancelled' THEN 1 END) as cancelledParcels
      FROM agents a
      LEFT JOIN parcels p ON a.id = p.createdBy AND p.createdAt >= ? AND p.createdAt <= ?
      GROUP BY a.id, a.name, a.email
      ORDER BY revenueGenerated DESC
    ''', [start, end]);

    return result.map((row) {
      final parcelsHandled = row['parcelsHandled'] as int;
      final deliveredParcels = row['deliveredParcels'] as int;
      final successRate = parcelsHandled > 0 ? (deliveredParcels / parcelsHandled) * 100 : 0.0;

      return {
        'agentId': row['id'],
        'agentName': row['name'],
        'agentEmail': row['email'],
        'parcelsHandled': parcelsHandled,
        'revenueGenerated': (row['revenueGenerated'] as num?)?.toDouble() ?? 0.0,
        'avgParcelValue': (row['avgParcelValue'] as num?)?.toDouble() ?? 0.0,
        'deliveredParcels': deliveredParcels,
        'cancelledParcels': row['cancelledParcels'] as int,
        'successRate': successRate,
      };
    }).toList();
  }

  // ==================== CHAT SYSTEM METHODS ====================

  /// Create or get existing conversation between two users
  Future<Conversation> getOrCreateConversation({
    required String participant1Id,
    required String participant1Name,
    required String participant2Id,
    required String participant2Name,
  }) async {
    final db = await _db;

    // Check if conversation already exists (either direction)
    final existingResult = await db.rawQuery('''
      SELECT * FROM conversations
      WHERE (participant1Id = ? AND participant2Id = ?)
         OR (participant1Id = ? AND participant2Id = ?)
    ''', [participant1Id, participant2Id, participant2Id, participant1Id]);

    if (existingResult.isNotEmpty) {
      return Conversation.fromMap(existingResult.first);
    }

    // Create new conversation
    final conversationId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    final conversation = Conversation(
      id: conversationId,
      participant1Id: participant1Id,
      participant1Name: participant1Name,
      participant2Id: participant2Id,
      participant2Name: participant2Name,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('conversations', conversation.toMap());
    await _logActivity('Created conversation with $participant2Name', participant1Id);

    return conversation;
  }

  /// Send a message in a conversation
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String messageText,
    String messageType = 'text',
  }) async {
    final db = await _db;
    final messageId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    final message = Message(
      id: messageId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      messageText: messageText,
      messageType: messageType,
      isRead: false,
      sentAt: now,
    );

    // Insert message
    await db.insert('messages', message.toMap());

    // Update conversation with last message info
    await db.update(
      'conversations',
      {
        'lastMessageId': messageId,
        'lastMessageText': messageText,
        'lastMessageTime': now,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    await _logActivity('Sent message to $receiverName', senderId);

    return message;
  }

  /// Get all conversations for a user
  Future<List<Conversation>> getUserConversations(String userId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT * FROM conversations
      WHERE participant1Id = ? OR participant2Id = ?
      ORDER BY updatedAt DESC
    ''', [userId, userId]);

    return result.map((map) => Conversation.fromMap(map)).toList();
  }

  /// Get messages for a conversation
  Future<List<Message>> getConversationMessages(String conversationId, {int limit = 50}) async {
    final db = await _db;
    final result = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'sentAt DESC',
      limit: limit,
    );

    final messages = result.map((map) => Message.fromMap(map)).toList().reversed.toList();

    // Mark messages as delivered when they are fetched by the receiver
    await _markMessagesAsDelivered(conversationId);

    return messages;
  }

  /// Mark messages as delivered when conversation is opened
  Future<void> _markMessagesAsDelivered(String conversationId) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    try {
      await db.update(
        'messages',
        {
          'deliveredAt': now,
          'deliveryStatus': 'delivered',
        },
        where: 'conversationId = ? AND deliveryStatus = "sent"',
        whereArgs: [conversationId],
      );
    } catch (e) {
      debugPrint('Error marking messages as delivered: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'messages',
      {
        'isRead': 1,
        'readAt': now,
        'deliveryStatus': 'read',
      },
      where: 'conversationId = ? AND receiverId = ? AND isRead = 0',
      whereArgs: [conversationId, userId],
    );
  }

  /// Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM messages
      WHERE receiverId = ? AND isRead = 0
    ''', [userId]);

    return result.first['count'] as int;
  }

  /// Get unread message count for a specific conversation
  Future<int> getConversationUnreadCount(String conversationId, String userId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM messages
      WHERE conversationId = ? AND receiverId = ? AND isRead = 0
    ''', [conversationId, userId]);

    return result.first['count'] as int;
  }

  /// Get all agents/users for chat user selection
  Future<List<Agent>> getAvailableChatUsers(String currentUserId) async {
    final db = await _db;
    final result = await db.query(
      'agents',
      where: 'id != ? AND isFrozen = 0',
      whereArgs: [currentUserId],
      orderBy: 'name ASC',
    );

    return result.map((map) => Agent.fromMap(map)).toList();
  }

  /// Delete a conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    final db = await _db;

    // Delete all messages in the conversation
    await db.delete('messages', where: 'conversationId = ?', whereArgs: [conversationId]);

    // Delete the conversation
    await db.delete('conversations', where: 'id = ?', whereArgs: [conversationId]);
  }

  /// Get updated delivery status for messages (for real-time updates)
  Future<List<Message>> getUpdatedMessages(String conversationId, List<String> messageIds) async {
    final db = await _db;

    if (messageIds.isEmpty) return [];

    final placeholders = messageIds.map((_) => '?').join(',');
    final result = await db.rawQuery('''
      SELECT * FROM messages
      WHERE conversationId = ? AND id IN ($placeholders)
      ORDER BY sentAt ASC
    ''', [conversationId, ...messageIds]);

    return result.map((map) => Message.fromMap(map)).toList();
  }


}

class User {
  final String id;
  final bool isAdmin;

  User({required this.id, required this.isAdmin});
}
