// Script to clean up test notifications from Firebase
// Run this script to remove all test notifications from the database

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./supervisor_user.json'); // Use existing service account

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://mybus-app-default-rtdb.firebaseio.com"
});

const db = admin.firestore();

async function cleanupTestNotifications() {
  console.log('🧹 Starting cleanup of test notifications...');
  
  try {
    // Get all notifications
    const notificationsRef = db.collection('notifications');
    const snapshot = await notificationsRef.get();
    
    if (snapshot.empty) {
      console.log('ℹ️ No notifications found in database');
      return;
    }
    
    console.log(`📊 Found ${snapshot.size} total notifications`);
    
    const batch = db.batch();
    let deletedCount = 0;
    
    snapshot.forEach((doc) => {
      const data = doc.data();
      
      // Check if it's a test notification
      const isTestNotification = 
        (data.title && data.title.includes('تجريبي')) ||
        (data.body && data.body.includes('تجريبي')) ||
        (data.data && data.data.source === 'test') ||
        (data.type === 'general' && data.title === 'إشعار تجريبي') ||
        (data.title && data.title.includes('test')) ||
        (data.body && data.body.includes('test'));
      
      if (isTestNotification) {
        console.log(`🗑️ Marking for deletion: ${data.title} (${doc.id})`);
        batch.delete(doc.ref);
        deletedCount++;
      }
    });
    
    if (deletedCount > 0) {
      await batch.commit();
      console.log(`✅ Successfully deleted ${deletedCount} test notifications`);
    } else {
      console.log('ℹ️ No test notifications found to delete');
    }
    
    // Show remaining notifications count
    const remainingSnapshot = await notificationsRef.get();
    console.log(`📊 Remaining notifications: ${remainingSnapshot.size}`);
    
  } catch (error) {
    console.error('❌ Error cleaning up test notifications:', error);
  }
}

async function showNotificationsSummary() {
  console.log('\n📋 Notifications Summary:');
  console.log('========================');
  
  try {
    const snapshot = await db.collection('notifications').get();
    
    if (snapshot.empty) {
      console.log('No notifications in database');
      return;
    }
    
    const notifications = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      notifications.push({
        id: doc.id,
        title: data.title,
        type: data.type,
        recipientId: data.recipientId,
        timestamp: data.timestamp,
        isTest: (data.title && data.title.includes('تجريبي')) ||
                (data.body && data.body.includes('تجريبي')) ||
                (data.data && data.data.source === 'test')
      });
    });
    
    // Group by type
    const byType = notifications.reduce((acc, notif) => {
      const type = notif.isTest ? 'test' : notif.type;
      acc[type] = (acc[type] || 0) + 1;
      return acc;
    }, {});
    
    console.log('Notifications by type:');
    Object.entries(byType).forEach(([type, count]) => {
      console.log(`  ${type}: ${count}`);
    });
    
    console.log(`\nTotal: ${notifications.length} notifications`);
    
    // Show recent notifications
    const recent = notifications
      .sort((a, b) => {
        const aTime = a.timestamp?.toDate?.() || new Date(0);
        const bTime = b.timestamp?.toDate?.() || new Date(0);
        return bTime - aTime;
      })
      .slice(0, 5);
    
    console.log('\nRecent notifications:');
    recent.forEach((notif, index) => {
      const time = notif.timestamp?.toDate?.() || 'Unknown time';
      console.log(`  ${index + 1}. ${notif.title} (${notif.type}) - ${time}`);
    });
    
  } catch (error) {
    console.error('❌ Error getting notifications summary:', error);
  }
}

// Main execution
async function main() {
  console.log('🚀 Firebase Test Notifications Cleanup Tool');
  console.log('===========================================\n');
  
  // Show summary before cleanup
  await showNotificationsSummary();
  
  // Perform cleanup
  await cleanupTestNotifications();
  
  // Show summary after cleanup
  await showNotificationsSummary();
  
  console.log('\n✅ Cleanup completed!');
  process.exit(0);
}

// Run the script
main().catch((error) => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});
