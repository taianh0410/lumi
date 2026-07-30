import { ChatSession } from '../models/ChatSession.js';
import { Message } from '../models/Message.js';
import { forwardChatToAiEngine } from '../services/aiEngineClient.js';

function generateRoomId() {
  return `room_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
}

// POST /api/chat/session
export async function createSession(req, res) {
  try {
    const userId = req.user?.uid;
    const { title = 'Phiên học mới', classId = null } = req.body;

    const session = await ChatSession.create({
      userId,
      roomId: generateRoomId(),
      title: String(title).trim(),
      classId: classId || null,
    });

    return res.status(201).json({
      message: 'Tạo phiên chat thành công.',
      session: {
        id: session._id,
        roomId: session.roomId,
        title: session.title,
        userId: session.userId,
        classId: session.classId,
        createdAt: session.createdAt,
      },
    });
  } catch (error) {
    console.error('[CHAT][CREATE_SESSION]', error.message);
    return res.status(500).json({ message: 'Lỗi tạo phiên chat.', detail: error.message });
  }
}

// POST /api/chat/message
export async function sendMessage(req, res) {
  try {
    const { sessionId, content } = req.body;

    if (!sessionId) {
      return res.status(400).json({ message: 'Thiếu sessionId.' });
    }
    if (!content || !String(content).trim()) {
      return res.status(400).json({ message: 'Thiếu nội dung tin nhắn.' });
    }

    const session = await ChatSession.findById(sessionId);
    if (!session) {
      return res.status(404).json({ message: 'Không tìm thấy phiên chat.' });
    }

    // Chỉ cho phép chủ session nhắn tin
    if (String(session.userId) !== String(req.user?.uid)) {
      return res.status(403).json({ message: 'Không có quyền gửi tin nhắn vào phiên này.' });
    }

    // 1. Lưu tin nhắn của user
    const userMessage = await Message.create({
      sessionId,
      sender: 'user',
      content: String(content).trim(),
    });

    // 2. Gọi AI Engine (Python FastAPI / Gemini)
    let aiText = 'Đây là câu trả lời từ AI (placeholder).';
    let aiMetadata = {};

    try {
      const aiResponse = await forwardChatToAiEngine({
        question: userMessage.content,
        room_id: session.roomId,
        user_id: String(session.userId),
      });

      if (aiResponse.status < 400 && aiResponse.data?.answer) {
        aiText = aiResponse.data.answer;
        aiMetadata = { sources: aiResponse.data.sources ?? [] };
      }
    } catch (aiError) {
      // AI Engine không bắt buộc phải chạy — tiếp tục với placeholder
      console.warn('[CHAT][AI_ENGINE] Unreachable, using placeholder:', aiError.message);
    }

    // 3. Lưu tin nhắn của AI
    const aiMessage = await Message.create({
      sessionId,
      sender: 'ai',
      content: aiText,
      metadata: aiMetadata,
    });

    return res.status(200).json({
      userMessage: _formatMessage(userMessage),
      aiMessage: _formatMessage(aiMessage),
    });
  } catch (error) {
    console.error('[CHAT][SEND_MESSAGE]', error.message);
    return res.status(500).json({ message: 'Lỗi gửi tin nhắn.', detail: error.message });
  }
}

// GET /api/chat/session/:sessionId
export async function getHistory(req, res) {
  try {
    const { sessionId } = req.params;

    const session = await ChatSession.findById(sessionId);
    if (!session) {
      return res.status(404).json({ message: 'Không tìm thấy phiên chat.' });
    }

    if (String(session.userId) !== String(req.user?.uid)) {
      return res.status(403).json({ message: 'Không có quyền xem lịch sử phiên này.' });
    }

    const messages = await Message.find({ sessionId }).sort({ createdAt: 1 });

    return res.status(200).json({
      session: {
        id: session._id,
        roomId: session.roomId,
        title: session.title,
        createdAt: session.createdAt,
      },
      messages: messages.map(_formatMessage),
    });
  } catch (error) {
    console.error('[CHAT][GET_HISTORY]', error.message);
    return res.status(500).json({ message: 'Lỗi lấy lịch sử chat.', detail: error.message });
  }
}

function _formatMessage(msg) {
  return {
    id: msg._id,
    sessionId: msg.sessionId,
    sender: msg.sender,
    content: msg.content,
    metadata: msg.metadata,
    createdAt: msg.createdAt,
  };
}
