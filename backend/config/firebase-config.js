import dotenv from 'dotenv';
dotenv.config(); // ✅ required to load FIREBASE_SA_PATH

import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

let db = null;

export const initializeFirebase = () => {
  try {
    // Read service account key
    const serviceAccount = JSON.parse(
      readFileSync(join(__dirname, 'firebase-service-account.json'), 'utf8')
    );

    // Initialize Firebase Admin SDK
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com`
    });

    // Initialize Firestore
    db = admin.firestore();
    console.log('Firebase initialized successfully');
    
    return db;
  } catch (error) {
    console.error('Firebase initialization error:', error);
    process.exit(1);
  }
};

export const getFirestore = () => {
  if (!db) {
    throw new Error('Firestore not initialized. Call initializeFirebase() first.');
  }
  return db;
};

export { admin };
