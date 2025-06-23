# Parcel Cancellation Feature Test Plan

## Overview
This document outlines the testing plan for the new parcel cancellation feature in ZipBus.

## Feature Requirements ✅
1. **Cancellation Allowed**: Only parcels with status 'Pending' can be cancelled
2. **Cancellation Blocked**: Parcels with status 'In Transit' or 'Delivered' cannot be cancelled
3. **Status Update**: Cancelled parcels should have status 'Cancelled'
4. **Confirmation Dialog**: User must confirm cancellation before proceeding
5. **Notifications**: Both sender and receiver should be notified of cancellation
6. **Visual Indicators**: Cancelled parcels should be visually distinct (red color)
7. **Analytics**: Cancelled parcels should appear in analytics dashboard

## Test Cases

### Test Case 1: Cancel Pending Parcel
**Steps:**
1. Create a new parcel (status will be 'Pending')
2. Go to parcel list
3. Try to change status from 'Pending' to 'Cancelled'
4. Confirm cancellation in dialog

**Expected Results:**
- Confirmation dialog appears with parcel details
- After confirmation, parcel status changes to 'Cancelled'
- Parcel appears with red background/text
- SMS notifications sent to sender and receiver
- Analytics updated to include cancelled parcel

### Test Case 2: Cannot Cancel In Transit Parcel
**Steps:**
1. Create a parcel and change status to 'In Transit'
2. Try to change status from 'In Transit'

**Expected Results:**
- 'Cancelled' option should NOT appear in status dropdown
- Only 'Delivered' option should be available

### Test Case 3: Cannot Cancel Delivered Parcel
**Steps:**
1. Create a parcel and change status to 'Delivered'
2. Try to change status from 'Delivered'

**Expected Results:**
- No status change options should be available
- Status dropdown should be empty or disabled

### Test Case 4: Cancellation Dialog Details
**Steps:**
1. Try to cancel a pending parcel
2. Review confirmation dialog

**Expected Results:**
- Dialog shows warning icon
- Dialog displays parcel details (tracking, from, to, sender, amount)
- Warning message about action being irreversible
- Two buttons: "Keep Parcel" and "Cancel Parcel"
- "Cancel Parcel" button should be red

### Test Case 5: Analytics Integration
**Steps:**
1. Cancel some parcels
2. Go to Analytics Dashboard

**Expected Results:**
- Cancelled parcels count appears in metrics
- Cancelled parcels included in pie chart (red section)
- Total counts are accurate

## Implementation Files Modified ✅
- `lib/screens/parcel_list_screen.dart` - Added cancellation logic and dialog
- `lib/services/database_service.dart` - Added cancellation notifications
- `lib/services/sms_service.dart` - Added cancellation message
- `lib/services/analytics_service.dart` - Added cancelled parcels tracking
- `lib/screens/analytics_dashboard_screen.dart` - Added cancelled metrics display

## SMS Message Format
**Cancellation Message:**
```
❌ Your ZipBus parcel #[TRACKING_NUMBER] has been cancelled. Contact us for more details.
```

## Visual Design
- **Cancelled Status Badge**: Red background (#ffebee), red text (#c62828)
- **Confirmation Dialog**: Orange warning icon, red cancel button
- **Analytics Card**: Red icon for cancelled parcels count

## Notes
- Cancellation is permanent and cannot be undone
- Cancelled parcels remain in the system for record keeping
- Revenue from cancelled parcels may need special handling in analytics
- Consider adding cancellation reason field in future updates
