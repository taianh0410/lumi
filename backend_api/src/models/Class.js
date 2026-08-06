import mongoose from 'mongoose';

const classSchema = new mongoose.Schema(
  {
    name:          { type: String, required: true, trim: true },
    description:   { type: String, default: '' },
    teacherId:     { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    students:      [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    coverImage:    { type: String, default: '' },
    joinCode:      { type: String, required: true, unique: true, uppercase: true, trim: true },
    knowledgeTags: [{ type: String }],
  },
  { timestamps: true },
);

export const Class = mongoose.model('Class', classSchema);
