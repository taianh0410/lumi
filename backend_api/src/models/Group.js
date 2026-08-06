import mongoose from 'mongoose';

const groupSchema = new mongoose.Schema(
  {
    name:    { type: String, required: true, trim: true },
    adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    members: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    isDirect: { type: Boolean, default: false },
  },
  { timestamps: true },
);

export const Group = mongoose.model('Group', groupSchema);
