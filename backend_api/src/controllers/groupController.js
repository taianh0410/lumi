import mongoose from 'mongoose';

import { Group } from '../models/Group.js';

function getCurrentUserId(req) {
  return req.user?.id ?? req.user?.uid ?? req.user?.userId ?? null;
}

// POST /api/groups
// Body: { name, memberIds: [] }
export async function createGroup(req, res) {
  try {
    const adminId = getCurrentUserId(req);
    const { name, memberIds = [] } = req.body;

    if (!adminId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }

    if (!name || !String(name).trim()) {
      return res.status(400).json({ message: 'Thiếu tên nhóm.' });
    }

    // Validate ObjectId list
    const invalidIds = memberIds.filter((id) => !mongoose.isValidObjectId(id));
    if (invalidIds.length > 0) {
      return res.status(400).json({ message: 'Một số memberIds không hợp lệ.', invalidIds });
    }

    // Đảm bảo admin luôn có trong members, loại trùng
    const memberSet = [...new Set([String(adminId), ...memberIds.map(String)])];

    const group = await Group.create({
      name: String(name).trim(),
      adminId,
      members: memberSet,
    });

    return res.status(201).json({
      message: 'Tạo nhóm thành công.',
      group: {
        id: group._id,
        name: group.name,
        adminId: group.adminId,
        members: group.members,
        createdAt: group.createdAt,
      },
    });
  } catch (error) {
    console.error('[GROUP][CREATE]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}

// GET /api/groups
export async function getMyGroups(req, res) {
  try {
    const userId = getCurrentUserId(req);

    if (!userId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }

    const groups = await Group.find({ members: userId, isDirect: { $ne: true } })
      .populate('members', 'username role')
      .populate('adminId', 'username')
      .sort({ createdAt: -1 });

    return res.status(200).json({ groups });
  } catch (error) {
    console.error('[GROUP][GET_MY_GROUPS]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}

// POST /api/groups/direct
export async function getOrCreateDirectGroup(req, res) {
  try {
    const userId = getCurrentUserId(req);
    const { friendId } = req.body;

    if (!userId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }

    if (!friendId || !String(friendId).trim()) {
      return res.status(400).json({ message: 'Thiếu friendId.' });
    }

    if (!mongoose.isValidObjectId(friendId)) {
      return res.status(400).json({ message: 'friendId không hợp lệ.' });
    }

    if (String(userId) === String(friendId)) {
      return res.status(400).json({ message: 'Không thể tạo direct chat với chính mình.' });
    }

    let group = await Group.findOne({
      isDirect: true,
      members: { $all: [userId, friendId], $size: 2 },
    })
      .populate('members', 'username role')
      .populate('adminId', 'username');

    if (group) {
      return res.status(200).json({ group });
    }

    group = await Group.create({
      name: 'Direct Chat',
      adminId: userId,
      members: [userId, friendId],
      isDirect: true,
    });

    await group.populate('members', 'username role');
    await group.populate('adminId', 'username');

    return res.status(201).json({ group });
  } catch (error) {
    console.error('[GROUP][GET_OR_CREATE_DIRECT]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}
