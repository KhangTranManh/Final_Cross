import express from "express";
import dotenv from "dotenv";
dotenv.config(); // 🔥 Must be first — before any process.env usage

import connectDB from "./config/db.js";
import authRoutes from "./routes/auth.js";

// Now it's safe to use env vars
const apiKey = process.env.FIREBASE_API_KEY;
const port = process.env.PORT || 5000;

connectDB();

const app = express();
app.use(express.json());

// Routes
app.use("/auth", authRoutes);

app.listen(port, () => console.log(`Server running on port ${port}`));
