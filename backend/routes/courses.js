import express from 'express';
import Course from '../models/Course.js';
import Category from '../models/Category.js';
import { verifyToken } from '../controllers/authController.js';
import { getFirestore } from 'firebase-admin/firestore';

const router = express.Router();

// Get all courses with filters - Updated to avoid index issues
router.get('/', async (req, res) => {
  try {
    const db = getFirestore();
    const querySnapshot = await db.collection('courses')
      .where('isPublished', '==', true)
      .get();

    const courses = querySnapshot.docs.map(doc => ({
      id: doc.id,
      data: doc.data() // This creates the nested structure
    }));

    console.log('Sending courses response:', JSON.stringify(courses[0], null, 2)); // Log first course

    res.json({
      success: true,
      data: courses,
      count: courses.length
    });
  } catch (error) {
    console.error('Get courses error:', error);
    res.status(500).json({ error: 'Failed to fetch courses' });
  }
});

// Search courses
router.get('/search', async (req, res) => {
  try {
    const { q: searchTerm, category } = req.query;
    
    if (!searchTerm) {
      return res.status(400).json({ error: 'Search term is required' });
    }
    
    const courses = await Course.search(searchTerm, category);
    
    res.json({
      success: true,
      data: courses,
      count: courses.length
    });
  } catch (error) {
    console.error('Search courses error:', error);
    res.status(500).json({ error: 'Failed to search courses' });
  }
});

// Get course by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const course = await Course.findById(id);
    
    if (!course) {
      return res.status(404).json({ error: 'Course not found' });
    }
    
    res.json({
      success: true,
      data: course
    });
  } catch (error) {
    console.error('Get course error:', error);
    res.status(500).json({ error: 'Failed to fetch course' });
  }
});

// Create course (protected route)
router.post('/', verifyToken, async (req, res) => {
  try {
    const {
      title,
      description,
      instructor,
      difficulty,
      thumbnail,
      price,
      category,
      lessons
    } = req.body;
    
    if (!title || !description || !category) {
      return res.status(400).json({ 
        error: 'Title, description, and category are required' 
      });
    }
    
    // Calculate duration from lessons
    const duration = lessons ? 
      lessons.reduce((total, lesson) => total + (lesson.duration || 0), 0) : 0;
    
    const course = new Course({
      title,
      description,
      instructor: instructor || 'Unknown',
      duration,
      difficulty: difficulty || 'Beginner',
      thumbnail,
      price: price || 0,
      category,
      lessons: lessons || []
    });
    
    await course.save();
    
    res.status(201).json({
      success: true,
      message: 'Course created successfully',
      data: course
    });
  } catch (error) {
    console.error('Create course error:', error);
    res.status(500).json({ error: 'Failed to create course' });
  }
});

// Update course (protected route)
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const course = await Course.findById(id);
    if (!course) {
      return res.status(404).json({ error: 'Course not found' });
    }
    
    // Recalculate duration if lessons are updated
    if (updates.lessons) {
      updates.duration = updates.lessons.reduce((total, lesson) => total + (lesson.duration || 0), 0);
    }
    
    await course.update(updates);
    
    res.json({
      success: true,
      message: 'Course updated successfully',
      data: course
    });
  } catch (error) {
    console.error('Update course error:', error);
    res.status(500).json({ error: 'Failed to update course' });
  }
});

// Add lesson to course (protected route)
router.post('/:id/lessons', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const lesson = req.body;
    
    const course = await Course.findById(id);
    if (!course) {
      return res.status(404).json({ error: 'Course not found' });
    }
    
    await course.addLesson(lesson);
    
    res.json({
      success: true,
      message: 'Lesson added successfully',
      data: course
    });
  } catch (error) {
    console.error('Add lesson error:', error);
    res.status(500).json({ error: 'Failed to add lesson' });
  }
});

// Delete course (protected route)
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const course = await Course.findById(id);
    if (!course) {
      return res.status(404).json({ error: 'Course not found' });
    }
    
    await course.delete();
    
    res.json({
      success: true,
      message: 'Course deleted successfully'
    });
  } catch (error) {
    console.error('Delete course error:', error);
    res.status(500).json({ error: 'Failed to delete course' });
  }
});

export default router;