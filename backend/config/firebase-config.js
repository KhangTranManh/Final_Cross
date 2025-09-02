import dotenv from 'dotenv';
dotenv.config(); // ✅ required to load FIREBASE_SA_PATH

import { getApps, initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { readFileSync } from 'fs';

const serviceAccount = JSON.parse(
  readFileSync(process.env.FIREBASE_SA_PATH, 'utf8')
);

if (!getApps().length) {
  initializeApp({ credential: cert(serviceAccount) });
}

export const db = getFirestore();
export const auth = getAuth();
