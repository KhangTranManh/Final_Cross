import express from "express";
import cors from "cors";
import dotenv from "dotenv";
dotenv.config();

import { initializeFirebase } from "./config/firebase-config.js";
import authRoutes from "./routes/auth.js";
import categoryRoutes from "./routes/categories.js";
import courseRoutes from "./routes/courses.js";
import enrollmentRoutes from "./routes/enrollments.js";

// Initialize Firebase
initializeFirebase();

const port = process.env.PORT || 5000;

const app = express();

// CORS configuration - MUST BE FIRST
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps, Postman)
    if (!origin) return callback(null, true);
    
    // Allow any localhost port for development
    if (origin.startsWith('http://localhost:') || 
        origin.startsWith('http://127.0.0.1:') ||
        origin.startsWith('https://localhost:') || 
        origin.startsWith('https://127.0.0.1:')) {
      return callback(null, true);
    }
    
    // Add your production domain here when deploying
    // if (origin === 'https://yourdomain.com') {
    //   return callback(null, true);
    // }
    
    // Reject all other origins
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Middleware for parsing JSON
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Routes
app.use("/auth", authRoutes);
app.use("/categories", categoryRoutes);
app.use("/courses", courseRoutes);
app.use("/enrollments", enrollmentRoutes);

// Health check
app.get("/", (req, res) => {
  res.json({ 
    message: "Final Cross API is running!", 
    status: "OK",
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  res.status(500).json({ 
    success: false, 
    message: err.message || 'Internal server error' 
  });
});

// 404 handler - catch all undefined routes
app.use((req, res) => {
  res.status(404).json({ 
    success: false, 
    message: `Route ${req.originalUrl} not found` 
  });
});

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});