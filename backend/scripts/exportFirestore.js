import { initializeFirebase, getFirestore } from '../config/firebase-config.js';
import { writeFileSync, mkdirSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Initialize Firebase
initializeFirebase();
const db = getFirestore();

async function exportCollection(collectionName) {
  try {
    console.log(`Exporting collection: ${collectionName}`);
    const snapshot = await db.collection(collectionName).get();
    
    if (snapshot.empty) {
      console.log(`Collection ${collectionName} is empty`);
      return [];
    }

    const documents = [];
    snapshot.forEach(doc => {
      documents.push({
        id: doc.id,
        data: doc.data()
      });
    });

    console.log(`Found ${documents.length} documents in ${collectionName}`);
    return documents;
  } catch (error) {
    console.error(`Error exporting collection ${collectionName}:`, error);
    return [];
  }
}

async function exportAllData() {
  try {
    console.log('Starting Firestore export...');
    
    // Get all collections
    const collections = await db.listCollections();
    const exportData = {};

    for (const collection of collections) {
      const collectionName = collection.id;
      const documents = await exportCollection(collectionName);
      exportData[collectionName] = documents;
    }

    // Create export with timestamp in scripts folder
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const exportFileName = `firestore-export-${timestamp}.json`;
    const exportPath = join(__dirname, exportFileName);

    // Write export file
    writeFileSync(exportPath, JSON.stringify(exportData, null, 2));
    
    console.log('\n=== EXPORT COMPLETE ===');
    console.log(`Export saved to: ${exportPath}`);
    console.log('\nExported collections:');
    
    Object.keys(exportData).forEach(collection => {
      console.log(`  - ${collection}: ${exportData[collection].length} documents`);
    });

    return exportData;
  } catch (error) {
    console.error('Export failed:', error);
    process.exit(1);
  }
}

// Export specific collections if you know their names
async function exportSpecificCollections(collectionNames) {
  try {
    console.log('Starting specific collections export...');
    const exportData = {};

    for (const collectionName of collectionNames) {
      const documents = await exportCollection(collectionName);
      exportData[collectionName] = documents;
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const exportFileName = `firestore-specific-export-${timestamp}.json`;
    const exportPath = join(__dirname, exportFileName);

    writeFileSync(exportPath, JSON.stringify(exportData, null, 2));
    
    console.log('\n=== SPECIFIC EXPORT COMPLETE ===');
    console.log(`Export saved to: ${exportPath}`);
    
    return exportData;
  } catch (error) {
    console.error('Specific export failed:', error);
    process.exit(1);
  }
}

// Run export based on command line arguments
const args = process.argv.slice(2);

if (args.length > 0) {
  // Export specific collections
  exportSpecificCollections(args).then(() => {
    console.log('Export completed successfully');
    process.exit(0);
  });
} else {
  // Export all collections
  exportAllData().then(() => {
    console.log('Export completed successfully');
    process.exit(0);
  });
}