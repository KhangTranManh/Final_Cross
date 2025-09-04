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

const router = express.Router();

// Public routes
router.post("/register", registerUser);
router.post("/login", loginUser);

// Protected routes (require authentication)
router.get("/profile", verifyToken, getUserProfile);
router.put("/profile", verifyToken, updateUserProfile);

// Admin routes (you may want to add admin verification middleware)
router.post("/claims/:uid", setCustomClaims);
router.delete("/user/:uid", deleteUser);

export default router;
