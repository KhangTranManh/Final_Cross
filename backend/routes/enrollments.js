import express from 'express';
import Enrollment from '../models/Enrollment.js';
import Course from '../models/Course.js';
import { verifyToken } from '../controllers/authController.js';

const router = express.Router();

// Get user's enrollments (protected route)
router.get('/my-enrollments', verifyToken, async (req, res) => {
  try {
    const { uid } = req.user;
    const { status } = req.query;
    
    const enrollments = await Enrollment.findByUser(uid, status);
    
    // Populate course data
    const enrollmentsWithCourses = await Promise.all(
      enrollments.map(async (enrollment) => {
        const course = await Course.findById(enrollment.courseId);
        return {
          ...enrollment,
          course
        };
      })
    );
    
    res.json({
      success: true,
      data: enrollmentsWithCourses,
      count: enrollmentsWithCourses.length
    });
  } catch (error) {
    console.error('Get enrollments error:', error);
    res.status(500).json({ error: 'Failed to fetch enrollments' });
  }
});

// Enroll in a course (protected route)
router.post('/', verifyToken, async (req, res) => {
  try {
    const { uid } = req.user;
    const { courseId } = req.body;
    
    if (!courseId) {
      return res.status(400).json({ error: 'Course ID is required' });
    }
    
    // Check if course exists
    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({ error: 'Course not found' });
    }
    
    // Check if already enrolled
    const existingEnrollment = await Enrollment.findByUserAndCourse(uid, courseId);
    if (existingEnrollment) {
      return res.status(400).json({ 
        error: 'Already enrolled in this course',
        enrollment: existingEnrollment
      });
    }
    
    // Create new enrollment
    const enrollment = new Enrollment({
      userId: uid,
      courseId
    });
    
    await enrollment.save();
    
    // Update course students count
    await course.updateStudentsCount(course.studentsCount + 1);
    
    res.status(201).json({
      success: true,
      message: 'Enrolled successfully',
      data: { ...enrollment, course }
    });
  } catch (error) {
    console.error('Enroll error:', error);
    res.status(500).json({ error: 'Failed to enroll in course' });
  }
});

// Get enrollment details (protected route)
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const { uid } = req.user;
    const { id } = req.params;
    
    const enrollment = await Enrollment.findById(id);
    
    if (!enrollment) {
      return res.status(404).json({ error: 'Enrollment not found' });
    }
    
    // Check if user owns this enrollment
    if (enrollment.userId !== uid) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    // Get course data
    const course = await Course.findById(enrollment.courseId);
    
    res.json({
      success: true,
      data: { ...enrollment, course }
    });
  } catch (error) {
    console.error('Get enrollment error:', error);
    res.status(500).json({ error: 'Failed to fetch enrollment' });
  }
});

// Complete a lesson (protected route)
router.post('/:id/lessons/:lessonId/complete', verifyToken, async (req, res) => {
  try {
    const { uid } = req.user;
    const { id, lessonId } = req.params;
    
    const enrollment = await Enrollment.findById(id);
    
    if (!enrollment) {
      return res.status(404).json({ error: 'Enrollment not found' });
    }
    
    // Check if user owns this enrollment
    if (enrollment.userId !== uid) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    await enrollment.completeLesson(lessonId);
    
    // Calculate progress
    const course = await Course.findById(enrollment.courseId);
    const totalLessons = course.lessons.length;
    const completedLessons = enrollment.completedLessons.length;
    const progress = totalLessons > 0 ? Math.round((completedLessons / totalLessons) * 100) : 0;
    
    await enrollment.updateProgress(progress);
    
    res.json({
      success: true,
      message: 'Lesson completed successfully',
      data: { ...enrollment, progress }
    });
  } catch (error) {
    console.error('Complete lesson error:', error);
    res.status(500).json({ error: 'Failed to complete lesson' });
  }
});

// Update progress (protected route)
router.put('/:id/progress', verifyToken, async (req, res) => {
  try {
    const { uid } = req.user;
    const { id } = req.params;
    const { progress } = req.body;
    
    if (progress < 0 || progress > 100) {
      return res.status(400).json({ error: 'Progress must be between 0 and 100' });
    }
    
    const enrollment = await Enrollment.findById(id);
    
    if (!enrollment) {
      return res.status(404).json({ error: 'Enrollment not found' });
    }
    
    // Check if user owns this enrollment
    if (enrollment.userId !== uid) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    await enrollment.updateProgress(progress);
    
    res.json({
      success: true,
      message: 'Progress updated successfully',
      data: enrollment
    });
  } catch (error) {
    console.error('Update progress error:', error);
    res.status(500).json({ error: 'Failed to update progress' });
  }
});

// Cancel enrollment (protected route)
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const { uid } = req.user;
    const { id } = req.params;
    
    const enrollment = await Enrollment.findById(id);
    
    if (!enrollment) {
      return res.status(404).json({ error: 'Enrollment not found' });
    }
    
    // Check if user owns this enrollment
    if (enrollment.userId !== uid) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    await enrollment.cancel();
    
    // Update course students count
    const course = await Course.findById(enrollment.courseId);
    if (course && course.studentsCount > 0) {
      await course.updateStudentsCount(course.studentsCount - 1);
    }
    
    res.json({
      success: true,
      message: 'Enrollment cancelled successfully'
    });
  } catch (error) {
    console.error('Cancel enrollment error:', error);
    res.status(500).json({ error: 'Failed to cancel enrollment' });
  }
});

export default router;