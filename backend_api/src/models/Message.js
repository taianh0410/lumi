import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema(
  {
    sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'ChatSession', required: true },
    sender:    { type: String, enum: ['user', 'ai'], required: true },
    content:   { type: String, required: true },
    // Dùng cho Heatmap và metadata phân tích sau này
    metadata:  { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

export const Message = mongoose.model('Message', messageSchema);
