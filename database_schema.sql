-- ZipBus Database Schema
-- Version: 10
-- This file documents the current database structure for ZipBus app

-- Agents Table
CREATE TABLE agents (
    id TEXT PRIMARY KEY,
    name TEXT,
    email TEXT UNIQUE,
    password TEXT,
    mobile TEXT,
    profilePicture TEXT,
    isAdmin INTEGER,
    isFrozen INTEGER
);

-- Parcels Table (Main table for parcel tracking)
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
    
    -- Payment fields (added in version 9)
    paymentMethod TEXT DEFAULT 'cash',
    paymentStatus TEXT DEFAULT 'pending',
    paymentReference TEXT,
    
    -- Delivery scheduling fields (added in version 9, ensured in version 10)
    preferredDeliveryDate TEXT,
    preferredDeliveryTime TEXT,
    deliveryInstructions TEXT,
    
    -- Photo proof fields (added in version 9)
    pickupPhotoPath TEXT,
    deliveryPhotoPath TEXT,
    signaturePath TEXT
);

-- Activities Table (for logging user actions)
CREATE TABLE activities (
    id TEXT PRIMARY KEY,
    time TEXT,
    user_id TEXT,
    action TEXT
);

-- Payment Records Table (for admin tracking - added in version 11)
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
);

-- Default Admin User
INSERT INTO agents (id, name, email, password, mobile, profilePicture, isAdmin, isFrozen) 
VALUES ('1', 'Admin User', 'admin@zipbus2.com', 'admin123', '1234567890', NULL, 1, 0);

-- Database Version History:
-- Version 1-6: Basic structure
-- Version 7: Added receivedBy, deliveredBy fields
-- Version 8: Added activities table
-- Version 9: Added payment, delivery schedule, and photo proof fields
-- Version 10: Enhanced delivery schedule field validation and debugging
-- Version 11: Added payment_records table for admin payment tracking

-- Delivery Schedule Fields Usage:
-- preferredDeliveryDate: ISO 8601 date string (e.g., "2024-01-15T00:00:00.000Z")
-- preferredDeliveryTime: Time string in HH:MM format (e.g., "14:30")
-- deliveryInstructions: Free text field for special delivery instructions

-- Status Values:
-- 'Pending': Parcel created, waiting for pickup
-- 'In Transit': Parcel picked up, being transported
-- 'Delivered': Parcel successfully delivered
-- 'Cancelled': Parcel cancelled (only from Pending status)

-- Payment Method Values:
-- 'cash': Cash on delivery
-- 'mobile_money': Mobile money payment

-- Payment Status Values:
-- 'pending': Payment not yet completed
-- 'paid': Payment completed successfully
-- 'failed': Payment failed

-- Useful Queries:

-- Get parcels with delivery schedules
SELECT trackingNumber, preferredDeliveryDate, preferredDeliveryTime, deliveryInstructions 
FROM parcels 
WHERE preferredDeliveryDate IS NOT NULL 
   OR preferredDeliveryTime IS NOT NULL 
   OR deliveryInstructions IS NOT NULL;

-- Get parcels by status
SELECT COUNT(*) as count, status FROM parcels GROUP BY status;

-- Get recent activities
SELECT * FROM activities ORDER BY time DESC LIMIT 10;

-- Get parcels with payment information
SELECT trackingNumber, amount, paymentMethod, paymentStatus, paymentReference
FROM parcels
WHERE paymentMethod = 'mobile_money';

-- Get all payment records (admin view)
SELECT * FROM payment_records ORDER BY paymentDate DESC;

-- Get payment statistics
SELECT
    COUNT(*) as total_payments,
    SUM(amount) as total_amount,
    paymentMethod,
    COUNT(*) as method_count
FROM payment_records
GROUP BY paymentMethod;

-- Get payments by agent
SELECT
    agentName,
    COUNT(*) as payment_count,
    SUM(amount) as total_collected
FROM payment_records
GROUP BY agentId, agentName
ORDER BY total_collected DESC;

-- Get payments by date range
SELECT * FROM payment_records
WHERE paymentDate BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY paymentDate DESC;
