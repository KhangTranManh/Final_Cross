import { db } from '../config/firebase-config.js';
import dotenv from 'dotenv';


dotenv.config();

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

    await db.collection('users').doc(user.localId).set({
      email,
      createdAt: new Date(),
    });

    // ✅ THIS LINE IS IMPORTANT:
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
