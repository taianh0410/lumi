import { Message } from '../models/Message.js';

export async function getMessagesByGroup(req, res) {
  try {
    const { groupId } = req.params;

    if (!groupId || !String(groupId).trim()) {
      return res.status(400).json({ message: 'Thiếu groupId.' });
    }

    const messages = await Message.find({ groupId: groupId.trim() })
      .populate('senderId', 'username role')
      .sort({ createdAt: 1 });

    return res.status(200).json({ messages });
  } catch (error) {
    console.error('[MESSAGE][GET_BY_GROUP]', error.message);
    return res.status(500).json({ message: 'Không thể lấy danh sách tin nhắn.', detail: error.message });
  }
}
