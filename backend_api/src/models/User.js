import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    username:       { type: String, required: true, unique: true, lowercase: true, trim: true },
    password:       { type: String, required: true },
    role:           { type: String, enum: ['student', 'teacher', 'admin'], default: 'student' },
    friends:        [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    friendRequests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true },
);

export const User = mongoose.model('User', userSchema);
