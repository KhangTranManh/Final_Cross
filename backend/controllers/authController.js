import { getFirestore, admin } from '../config/firebase-config.js';
import dotenv from 'dotenv';

dotenv.config();

// Verify Firebase ID token middleware
export const verifyToken = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Get current user profile
export const getUserProfile = async (req, res) => {
  try {
    const { uid } = req.user;
    const db = getFirestore();
    
    // Get user from Firestore
    const userDoc = await db.collection('users').doc(uid).get();
    
    // If user doesn't exist in Firestore, create from Firebase Auth
    if (!userDoc.exists) {
      const firebaseUser = await admin.auth().getUser(uid);
      const userData = {
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName || null,
        photoURL: firebaseUser.photoURL || null,
        emailVerified: firebaseUser.emailVerified,
        createdAt: new Date(firebaseUser.metadata.creationTime),
      };
      
      await db.collection('users').doc(uid).set(userData);
      
      return res.json({
        success: true,
        user: userData
      });
    }
    
    const userData = userDoc.data();
    res.json({
      success: true,
      user: {
        uid: userData.uid,
        email: userData.email,
        displayName: userData.displayName,
        photoURL: userData.photoURL,
        emailVerified: userData.emailVerified,
        createdAt: userData.createdAt,
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to get user profile' });
  }
};

// Update user profile
export const updateUserProfile = async (req, res) => {
  try {
    const { uid } = req.user;
    const updates = req.body;
    const db = getFirestore();
    
    // Remove sensitive fields
    delete updates.uid;
    delete updates.email;
    delete updates.emailVerified;
    
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    await userRef.update({
      ...updates,
      updatedAt: new Date()
    });
    
    const updatedUser = await userRef.get();
    const userData = updatedUser.data();
    
    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        uid: userData.uid,
        email: userData.email,
        displayName: userData.displayName,
        photoURL: userData.photoURL,
        emailVerified: userData.emailVerified,
      }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
};

// Set custom claims for user
export const setCustomClaims = async (req, res) => {
  try {
    const { uid } = req.params;
    const { claims } = req.body;
    const db = getFirestore();
    
    await admin.auth().setCustomUserClaims(uid, claims);
    
    // Update in Firestore
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    
    if (userDoc.exists) {
      await userRef.update({ 
        customClaims: claims,
        updatedAt: new Date()
      });
    }
    
    res.json({
      success: true,
      message: 'Custom claims set successfully'
    });
  } catch (error) {
    console.error('Set custom claims error:', error);
    res.status(500).json({ error: 'Failed to set custom claims' });
  }
};

// Delete user
export const deleteUser = async (req, res) => {
  try {
    const { uid } = req.params;
    const db = getFirestore();
    
    // Delete from Firebase Auth
    await admin.auth().deleteUser(uid);
    
    // Delete from Firestore
    await db.collection('users').doc(uid).delete();
    
    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
};

export const registerUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${process.env.FIREBASE_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email,
          password,
          returnSecureToken: true,
        }),
      }
    );

    const user = await response.json();

    if (!response.ok) {
      return res.status(400).json({ 
        success: false, 
        message: user.error?.message || 'Registration failed' 
      });
    }

    // Save user to Firestore
    const db = getFirestore();
    await db.collection('users').doc(user.localId).set({
      uid: user.localId,
      email,
      emailVerified: false,
      createdAt: new Date(),
    });

    return res.status(200).json({ 
      success: true, 
      message: 'User registered successfully',
      id: user.localId 
    });

  } catch (err) {
    return res.status(500).json({ 
      success: false, 
      message: err.message 
    });
  }
};

export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${process.env.FIREBASE_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, returnSecureToken: true }),
      }
    );

    const data = await response.json();

    if (!response.ok) {
      return res.status(400).json({ 
        success: false, 
        message: data.error?.message || 'Login failed' 
      });
    }

    return res.json({ 
      success: true, 
      message: 'Login successful', 
      token: data.idToken 
    });
  } catch (err) {
    return res.status(500).json({ 
      success: false, 
      message: err.message 
    });
  }
};