import { getFirestore } from '../config/firebase-config.js';
import { Timestamp } from 'firebase-admin/firestore';

class Category {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description;
    this.icon = data.icon;
    this.coursesCount = data.coursesCount || 0;
    this.createdAt = data.createdAt || Timestamp.now();
  }

  // Save category to Firestore
  async save() {
    const db = getFirestore();
    const categoryRef = this.id 
      ? db.collection('categories').doc(this.id)
      : db.collection('categories').doc();
    
    if (!this.id) {
      this.id = categoryRef.id;
    }

    await categoryRef.set({
      name: this.name,
      description: this.description,
      icon: this.icon,
      coursesCount: this.coursesCount,
      createdAt: this.createdAt
    });
    
    return this;
  }

  // Find category by ID
  static async findById(id) {
    const db = getFirestore();
    const categoryDoc = await db.collection('categories').doc(id).get();
    
    if (!categoryDoc.exists) {
      return null;
    }
    
    return new Category({ id, ...categoryDoc.data() });
  }

  // Get all categories
  static async findAll() {
    const db = getFirestore();
    const querySnapshot = await db.collection('categories').orderBy('name').get();
    
    return querySnapshot.docs.map(doc => new Category({ id: doc.id, ...doc.data() }));
  }

  // Update category
  async update(updates) {
    const db = getFirestore();
    const categoryRef = db.collection('categories').doc(this.id);
    
    await categoryRef.update(updates);
    
    // Update local instance
    Object.assign(this, updates);
    return this;
  }

  // Delete category
  async delete() {
    const db = getFirestore();
    await db.collection('categories').doc(this.id).delete();
  }

  // Update courses count
  async updateCoursesCount(count) {
    return await this.update({ coursesCount: count });
  }
}

export default Category;