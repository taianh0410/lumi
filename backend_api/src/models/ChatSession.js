import mongoose from 'mongoose';

const chatSessionSchema = new mongoose.Schema(
  {
    userId:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    classId: { type: mongoose.Schema.Types.ObjectId, ref: 'Class', default: null },
    roomId:  { type: String, required: true, trim: true },
    title:   { type: String, default: 'Phiên học mới' },
  },
  { timestamps: true },
);

export const ChatSession = mongoose.model('ChatSession', chatSessionSchema);
