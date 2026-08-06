import mongoose from 'mongoose';

import { User } from '../models/User.js';

function getCurrentUserId(req) {
  return req.user?.id ?? req.user?.uid ?? req.user?.userId ?? null;
}

// GET /api/friends/list
export async function getFriends(req, res) {
  try {
    const currentUserId = getCurrentUserId(req);

    if (!currentUserId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }

    const user = await User.findById(currentUserId).populate('friends', 'username role');

    if (!user) {
      return res.status(404).json({ message: 'Người dùng không tồn tại.' });
    }

    return res.status(200).json({ friends: user.friends ?? [] });
  } catch (error) {
    console.error('[FRIEND][GET_FRIENDS]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}

// GET /api/friends/pending
export async function getPendingRequests(req, res) {
  try {
    const currentUserId = getCurrentUserId(req);

    if (!currentUserId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }

    const user = await User.findById(currentUserId).populate(
      'friendRequests',
      'username role _id',
    );

    if (!user) {
      return res.status(404).json({ message: 'Người dùng không tồn tại.' });
    }

    return res.status(200).json({ requests: user.friendRequests ?? [] });
  } catch (error) {
    console.error('[FRIEND][GET_PENDING_REQUESTS]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}

// POST /api/friends/request
// Body: { targetUserId }
export async function sendRequest(req, res) {
  try {
    const senderId = getCurrentUserId(req);
    const { targetUserId } = req.body;

    if (!senderId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }

    if (!targetUserId) {
      return res.status(400).json({ message: 'Thiếu targetUserId.' });
    }
    if (String(senderId) === String(targetUserId)) {
      return res.status(400).json({ message: 'Không thể gửi lời mời cho chính mình.' });
    }
    if (!mongoose.isValidObjectId(targetUserId)) {
      return res.status(400).json({ message: 'targetUserId không hợp lệ.' });
    }

    const target = await User.findById(targetUserId);
    if (!target) {
      return res.status(404).json({ message: 'Người dùng không tồn tại.' });
    }

    const alreadyFriend = target.friends.some((id) => String(id) === String(senderId));
    if (alreadyFriend) {
      return res.status(409).json({ message: 'Hai người đã là bạn bè.' });
    }

    const alreadySent = target.friendRequests.some((id) => String(id) === String(senderId));
    if (alreadySent) {
      return res.status(409).json({ message: 'Lời mời kết bạn đã được gửi trước đó.' });
    }

    await User.findByIdAndUpdate(targetUserId, {
      $push: { friendRequests: senderId },
    });

    return res.status(200).json({ message: 'Đã gửi lời mời kết bạn.' });
  } catch (error) {
    console.error('[FRIEND][SEND_REQUEST]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}

// POST /api/friends/accept
// Body: { requesterId }  — ID của người đã gửi lời mời
export async function acceptRequest(req, res) {
  try {
    const acceptorId = getCurrentUserId(req);
    const { requesterId } = req.body;

    if (!acceptorId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }

    if (!requesterId) {
      return res.status(400).json({ message: 'Thiếu requesterId.' });
    }
    if (!mongoose.isValidObjectId(requesterId)) {
      return res.status(400).json({ message: 'requesterId không hợp lệ.' });
    }

    const acceptor = await User.findById(acceptorId);
    if (!acceptor) {
      return res.status(404).json({ message: 'Người dùng không tồn tại.' });
    }

    const hasPendingRequest = acceptor.friendRequests.some(
      (id) => String(id) === String(requesterId),
    );
    if (!hasPendingRequest) {
      return res.status(404).json({ message: 'Không tìm thấy lời mời kết bạn từ người này.' });
    }

    // Xoá khỏi friendRequests, thêm vào friends của cả 2
    await Promise.all([
      User.findByIdAndUpdate(acceptorId, {
        $pull: { friendRequests: requesterId },
        $addToSet: { friends: requesterId },
      }),
      User.findByIdAndUpdate(requesterId, {
        $addToSet: { friends: acceptorId },
      }),
    ]);

    return res.status(200).json({ message: 'Đã chấp nhận lời mời kết bạn.' });
  } catch (error) {
    console.error('[FRIEND][ACCEPT_REQUEST]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}
