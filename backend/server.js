import express from "express";
import dotenv from "dotenv";
dotenv.config(); // 🔥 Must be first — before any process.env usage

import { initializeFirebase } from "./config/firebase-config.js";
import authRoutes from "./routes/auth.js";
import categoryRoutes from "./routes/categories.js";
import courseRoutes from "./routes/courses.js";
import enrollmentRoutes from "./routes/enrollments.js";

// Initialize Firebase
initializeFirebase();

const port = process.env.PORT || 5000;

const app = express();
app.use(express.json());

// Routes
app.use("/auth", authRoutes);
app.use("/categories", categoryRoutes);
app.use("/courses", courseRoutes);
app.use("/enrollments", enrollmentRoutes);

// Health check
app.get("/", (req, res) => {
  res.json({ message: "Final Cross API is running!", status: "OK" });
});

app.listen(port, () => console.log(`Server running on port ${port}`));
