import { getFirestore } from '../config/firebase-config.js';
import { Timestamp } from 'firebase-admin/firestore';

class Enrollment {
  constructor(data) {
    this.id = data.id;
    this.userId = data.userId;
    this.courseId = data.courseId;
    this.enrolledAt = data.enrolledAt || Timestamp.now();
    this.progress = data.progress || 0;
    this.completedLessons = data.completedLessons || [];
    this.status = data.status || 'active'; // active, completed, cancelled
    this.lastAccessed = data.lastAccessed || Timestamp.now();
    this.completionDate = data.completionDate || null;
  }

  // Save enrollment to Firestore
  async save() {
    const db = getFirestore();
    const enrollmentRef = this.id 
      ? db.collection('enrollments').doc(this.id)
      : db.collection('enrollments').doc();
    
    if (!this.id) {
      this.id = enrollmentRef.id;
    }

    await enrollmentRef.set({
      userId: this.userId,
      courseId: this.courseId,
      enrolledAt: this.enrolledAt,
      progress: this.progress,
      completedLessons: this.completedLessons,
      status: this.status,
      lastAccessed: this.lastAccessed,
      completionDate: this.completionDate
    });
    
    return this;
  }

  // Find enrollment by ID
  static async findById(id) {
    const db = getFirestore();
    const enrollmentDoc = await db.collection('enrollments').doc(id).get();
    
    if (!enrollmentDoc.exists) {
      return null;
    }
    
    return new Enrollment({ id, ...enrollmentDoc.data() });
  }

  // Find enrollment by user and course
  static async findByUserAndCourse(userId, courseId) {
    const db = getFirestore();
    const querySnapshot = await db.collection('enrollments')
      .where('userId', '==', userId)
      .where('courseId', '==', courseId)
      .limit(1)
      .get();
    
    if (querySnapshot.empty) {
      return null;
    }
    
    const doc = querySnapshot.docs[0];
    return new Enrollment({ id: doc.id, ...doc.data() });
  }

  // Get user's enrollments
  static async findByUser(userId, status = null) {
    const db = getFirestore();
    let query = db.collection('enrollments').where('userId', '==', userId);
    
    if (status) {
      query = query.where('status', '==', status);
    }
    
    query = query.orderBy('enrolledAt', 'desc');
    
    const querySnapshot = await query.get();
    return querySnapshot.docs.map(doc => new Enrollment({ id: doc.id, ...doc.data() }));
  }

  // Get course enrollments
  static async findByCourse(courseId) {
    const db = getFirestore();
    const querySnapshot = await db.collection('enrollments')
      .where('courseId', '==', courseId)
      .orderBy('enrolledAt', 'desc')
      .get();
    
    return querySnapshot.docs.map(doc => new Enrollment({ id: doc.id, ...doc.data() }));
  }

  // Update enrollment
  async update(updates) {
    const db = getFirestore();
    const enrollmentRef = db.collection('enrollments').doc(this.id);
    
    updates.lastAccessed = Timestamp.now();
    await enrollmentRef.update(updates);
    
    // Update local instance
    Object.assign(this, updates);
    return this;
  }

  // Mark lesson as completed
  async completeLesson(lessonId) {
    if (!this.completedLessons.includes(lessonId)) {
      this.completedLessons.push(lessonId);
      
      // Update progress (you'll need to get the course to calculate this properly)
      // For now, we'll just update the completed lessons
      return await this.update({ 
        completedLessons: this.completedLessons 
      });
    }
    return this;
  }

  // Update progress
  async updateProgress(progress) {
    const updates = { progress };
    
    // If progress is 100%, mark as completed
    if (progress >= 100 && this.status !== 'completed') {
      updates.status = 'completed';
      updates.completionDate = Timestamp.now();
    }
    
    return await this.update(updates);
  }

  // Cancel enrollment
  async cancel() {
    return await this.update({ status: 'cancelled' });
  }

  // Delete enrollment
  async delete() {
    const db = getFirestore();
    await db.collection('enrollments').doc(this.id).delete();
  }
}

export default Enrollment;