import express from "express";
import {
  registerUser,
  loginUser,
  verifyToken,
  getUserProfile,
  updateUserProfile,
  setCustomClaims,
  deleteUser,
} from "../controllers/authController.js";
import { validateRegistration } from '../middleware/validate.js';

const router = express.Router();

// Public routes
router.post("/register", validateRegistration, registerUser);
router.post("/login", loginUser);

// Protected routes (require authentication)
router.get("/profile", verifyToken, getUserProfile);
router.put("/profile", verifyToken, updateUserProfile);

// Admin routes (you may want to add admin verification middleware)
router.post("/claims/:uid", verifyToken, setCustomClaims);
router.delete("/user/:uid", verifyToken, deleteUser);

export default router;
