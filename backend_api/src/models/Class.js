import mongoose from 'mongoose';

const classSchema = new mongoose.Schema(
  {
    name:      { type: String, required: true, trim: true },
    teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    students:  [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true },
);

export const Class = mongoose.model('Class', classSchema);
