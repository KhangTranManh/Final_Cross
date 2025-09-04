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
    
    // Get user from Firestore
    let user = await User.findByUid(uid);
    
    // If user doesn't exist in Firestore, create from Firebase Auth
    if (!user) {
      const firebaseUser = await admin.auth().getUser(uid);
      user = new User({
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        emailVerified: firebaseUser.emailVerified,
        createdAt: new Date(firebaseUser.metadata.creationTime),
      });
      await user.save();
    }
    
    res.json({
      success: true,
      user: {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        createdAt: user.createdAt,
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
    
    // Remove sensitive fields
    delete updates.uid;
    delete updates.email;
    delete updates.emailVerified;
    
    let user = await User.findByUid(uid);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    await user.update(updates);
    
    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
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
    
    await admin.auth().setCustomUserClaims(uid, claims);
    
    // Update in Firestore
    const user = await User.findByUid(uid);
    if (user) {
      await user.update({ customClaims: claims });
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
    
    // Delete from Firebase Auth
    await admin.auth().deleteUser(uid);
    
    // Delete from Firestore
    const user = await User.findByUid(uid);
    if (user) {
      await user.delete();
    }
    
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
      return res.status(400).json({ msg: user.error?.message || 'Register failed' });
    }

    // Get Firestore instance and save user
    const db = getFirestore();
    await db.collection('users').doc(user.localId).set({
      email,
      createdAt: new Date(),
    });

    return res.status(200).json({ msg: 'User registered', id: user.localId });

  } catch (err) {
    return res.status(500).json({ msg: err.message });
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
      return res.status(response.status).json({ msg: data.error?.message || 'LOGIN_FAILED' });
    }

    return res.json({ msg: 'Login successful', token: data.idToken });
  } catch (err) {
    return res.status(500).json({ msg: err.message });
  }
};

console.log('Firebase key:', process.env.FIREBASE_API_KEY);
