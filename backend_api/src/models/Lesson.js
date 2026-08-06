import mongoose from 'mongoose';

const lessonSchema = new mongoose.Schema(
  {
    classId: { type: mongoose.Schema.Types.ObjectId, ref: 'Class', required: true },
    title: { type: String, required: true, trim: true },
    order: { type: Number, default: 0 },
    contentScript: { type: String, default: '' },
    resources: [{ type: String }],
  },
  { timestamps: true },
);

export const Lesson = mongoose.model('Lesson', lessonSchema);