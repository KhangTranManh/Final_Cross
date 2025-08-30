import { body, validationResult } from 'express-validator';
import express from "express";
import { registerUser, loginUser } from "../controllers/authController.js";
import { validateRegistration } from '../middleware/validate.js';

const router = express.Router();

export const validateRegistration = [
  body('email')
    .isEmail()
    .withMessage('Please enter a valid email'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ msg: errors.array()[0].msg });
    }
    next();
  }
];

router.post("/register", validateRegistration, registerUser);
router.post("/login", loginUser);

export default router;