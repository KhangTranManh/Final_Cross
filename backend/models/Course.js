import { getFirestore } from '../config/firebase-config.js';
import { Timestamp } from 'firebase-admin/firestore';

class Course {
  constructor(data) {
    this.id = data.id;
    this.title = data.title;
    this.description = data.description;
    this.instructor = data.instructor;
    this.duration = data.duration;
    this.difficulty = data.difficulty;
    this.thumbnail = data.thumbnail;
    this.price = data.price;
    this.rating = data.rating || 0;
    this.studentsCount = data.studentsCount || 0;
    this.category = data.category;
    this.lessons = data.lessons || [];
    this.isPublished = data.isPublished || false;
    this.createdAt = data.createdAt || Timestamp.now();
    this.updatedAt = data.updatedAt || Timestamp.now();
  }

  // Save course to Firestore
  async save() {
    const db = getFirestore();
    const courseRef = this.id 
      ? db.collection('courses').doc(this.id)
      : db.collection('courses').doc();
    
    if (!this.id) {
      this.id = courseRef.id;
    }

    this.updatedAt = Timestamp.now();

    await courseRef.set({
      title: this.title,
      description: this.description,
      instructor: this.instructor,
      duration: this.duration,
      difficulty: this.difficulty,
      thumbnail: this.thumbnail,
      price: this.price,
      rating: this.rating,
      studentsCount: this.studentsCount,
      category: this.category,
      lessons: this.lessons,
      isPublished: this.isPublished,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    });
    
    return this;
  }

  // Find course by ID
  static async findById(id) {
    const db = getFirestore();
    const courseDoc = await db.collection('courses').doc(id).get();
    
    if (!courseDoc.exists) {
      return null;
    }
    
    return new Course({ id, ...courseDoc.data() });
  }

  // Get all courses with optional filters - SIMPLIFIED to avoid index requirements
  static async findAll(filters = {}) {
    const db = getFirestore();
    let query = db.collection('courses');

    // Only apply the isPublished filter OR sorting, not both
    if (filters.isPublished !== undefined) {
      query = query.where('isPublished', '==', filters.isPublished);
      // Don't add ordering when filtering by isPublished
    } else if (filters.category) {
      // If filtering by category, we can still sort
      query = query.where('category', '==', filters.category);
      if (filters.sortBy && filters.sortBy !== 'createdAt') {
        const direction = filters.sortOrder === 'desc' ? 'desc' : 'asc';
        query = query.orderBy(filters.sortBy, direction);
      }
    } else {
      // Only sort if no other filters are applied
      if (filters.sortBy) {
        const direction = filters.sortOrder === 'desc' ? 'desc' : 'asc';
        query = query.orderBy(filters.sortBy, direction);
      } else {
        query = query.orderBy('createdAt', 'desc');
      }
    }

    // Apply difficulty filter if no other complex filters
    if (filters.difficulty && !filters.isPublished && !filters.category) {
      query = query.where('difficulty', '==', filters.difficulty);
    }

    // Apply pagination
    if (filters.limit) {
      query = query.limit(filters.limit);
    }

    const querySnapshot = await query.get();
    let courses = querySnapshot.docs.map(doc => new Course({ id: doc.id, ...doc.data() }));

    // Apply client-side filtering for complex combinations
    if (filters.isPublished !== undefined) {
      courses = courses.filter(course => course.isPublished === filters.isPublished);
    }
    
    if (filters.difficulty && (filters.isPublished !== undefined || filters.category)) {
      courses = courses.filter(course => course.difficulty === filters.difficulty);
    }

    // Apply client-side sorting if needed
    if (filters.isPublished !== undefined && filters.sortBy) {
      courses.sort((a, b) => {
        let aValue = a[filters.sortBy];
        let bValue = b[filters.sortBy];
        
        if (filters.sortBy === 'createdAt') {
          aValue = aValue.toMillis ? aValue.toMillis() : new Date(aValue).getTime();
          bValue = bValue.toMillis ? bValue.toMillis() : new Date(bValue).getTime();
        }
        
        const direction = filters.sortOrder === 'desc' ? -1 : 1;
        return aValue > bValue ? direction : aValue < bValue ? -direction : 0;
      });
    }

    return courses;
  }

  // Get published courses only - Simple query
  static async findPublished(limit = null) {
    const db = getFirestore();
    let query = db.collection('courses').where('isPublished', '==', true);
    
    if (limit) {
      query = query.limit(limit);
    }

    const querySnapshot = await query.get();
    return querySnapshot.docs.map(doc => new Course({ id: doc.id, ...doc.data() }));
  }

  // Search courses - Get all and filter client-side
  static async search(searchTerm, category = null) {
    const db = getFirestore();
    let query = db.collection('courses');
    
    if (category) {
      query = query.where('category', '==', category);
    }

    const querySnapshot = await query.get();
    
    // Filter by search term and published status client-side
    const courses = querySnapshot.docs
      .map(doc => new Course({ id: doc.id, ...doc.data() }))
      .filter(course => 
        course.isPublished && (
          course.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
          course.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
          course.instructor.toLowerCase().includes(searchTerm.toLowerCase())
        )
      );

    return courses;
  }

  // Update course
  async update(updates) {
    const db = getFirestore();
    const courseRef = db.collection('courses').doc(this.id);
    
    updates.updatedAt = Timestamp.now();
    await courseRef.update(updates);
    
    // Update local instance
    Object.assign(this, updates);
    return this;
  }

  // Delete course
  async delete() {
    const db = getFirestore();
    await db.collection('courses').doc(this.id).delete();
  }

  // Add lesson
  async addLesson(lesson) {
    this.lessons.push({
      ...lesson,
      id: lesson.id || `lesson-${Date.now()}`,
      order: this.lessons.length + 1
    });
    
    // Recalculate total duration
    this.duration = this.lessons.reduce((total, lesson) => total + (lesson.duration || 0), 0);
    
    return await this.update({ lessons: this.lessons, duration: this.duration });
  }

  // Update students count
  async updateStudentsCount(count) {
    return await this.update({ studentsCount: count });
  }

  // Update rating
  async updateRating(newRating) {
    return await this.update({ rating: newRating });
  }
}

export default Course;