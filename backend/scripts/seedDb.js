import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import User from '../models/User.js';

const users = [
  {
    email: 'test@example.com',
    password: 'test123'
  },
  {
    email: 'admin@example.com',
    password: 'admin123'
  }
];

async function seedDatabase() {
  try {
    await mongoose.connect('mongodb://localhost:27017/elearning');
    
    // Clear existing users
    await User.deleteMany({});
    
    // Hash passwords and create users
    const hashedUsers = await Promise.all(
      users.map(async (user) => ({
        ...user,
        password: await bcrypt.hash(user.password, 10)
      }))
    );
    
    await User.insertMany(hashedUsers);
    console.log('Database seeded successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding database:', error);
    process.exit(1);
  }
}

seedDatabase();