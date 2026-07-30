import mongoose from 'mongoose';

export async function connectDB() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('MONGODB_URI không được cấu hình trong .env');
  }

  await mongoose.connect(uri);
  console.log(`[MongoDB] Connected: ${mongoose.connection.host}`);
}
