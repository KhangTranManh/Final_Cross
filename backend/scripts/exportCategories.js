import { initializeFirebase, getFirestore } from '../config/firebase-config.js';
import { writeFileSync, mkdirSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Initialize Firebase
initializeFirebase();
const db = getFirestore();

async function exportCategories() {
  try {
    console.log('Exporting categories...');
    
    // Try common collection names for categories
    const possibleCollectionNames = [
      'categories', 
      'category', 
      'Category', 
      'Categories',
      'course_categories',
      'courseCategories'
    ];
    
    let categoriesData = null;
    let foundCollectionName = null;
    
    for (const collectionName of possibleCollectionNames) {
      try {
        const snapshot = await db.collection(collectionName).get();
        if (!snapshot.empty) {
          foundCollectionName = collectionName;
          categoriesData = [];
          
          snapshot.forEach(doc => {
            categoriesData.push({
              id: doc.id,
              ...doc.data()
            });
          });
          
          console.log(`Found categories in collection: ${collectionName}`);
          break;
        }
      } catch (error) {
        // Collection doesn't exist, continue to next
        continue;
      }
    }
    
    if (!categoriesData) {
      console.log('No categories collection found. Trying to list all collections...');
      const collections = await db.listCollections();
      console.log('Available collections:');
      collections.forEach(col => console.log(`  - ${col.id}`));
      return;
    }
    
    // Export categories to scripts folder
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const exportFileName = `categories-export-${timestamp}.json`;
    const exportPath = join(__dirname, exportFileName);
    
    writeFileSync(exportPath, JSON.stringify(categoriesData, null, 2));
    
    console.log('\n=== CATEGORIES EXPORT COMPLETE ===');
    console.log(`Collection: ${foundCollectionName}`);
    console.log(`Documents: ${categoriesData.length}`);
    console.log(`Export saved to: ${exportPath}`);
    
    // Display categories summary
    console.log('\nCategories found:');
    categoriesData.forEach((category, index) => {
      console.log(`${index + 1}. ${category.name || category.title || category.id} ${category.description ? `(${category.description})` : ''}`);
    });
    
  } catch (error) {
    console.error('Categories export failed:', error);
    process.exit(1);
  }
}

exportCategories().then(() => {
  console.log('Categories export completed successfully');
  process.exit(0);
});