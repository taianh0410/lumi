import { getFirestore } from '../config/firebase.js';


function serializeMessage(doc) {
  return {
    id: doc.id,
    ...doc.data(),
  };
}

export async function createMessage(req, res) {
  try {
    const { roomId, text } = req.body;

    if (!roomId || !roomId.trim()) {
      return res.status(400).json({ message: 'Thiếu roomId.' });
    }

    if (!text || !text.trim()) {
      return res.status(400).json({ message: 'Thiếu nội dung tin nhắn.' });
    }

    const messagePayload = {
      roomId: roomId.trim(),
      userId: req.user.userId || req.user.uid,
      senderRole: req.user.role,
      text: text.trim(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const db = getFirestore();
    const roomSnap = await db.collection('rooms').doc(messagePayload.roomId).get();

    if (!roomSnap.exists) {
      return res.status(404).json({
        message: 'Room không tồn tại.',
        roomId: messagePayload.roomId,
      });
    }

    const messageRef = await db.collection('messages').add(messagePayload);
    const messageSnap = await messageRef.get();

    return res.status(201).json({
      message: 'Lưu tin nhắn thành công.',
      chatMessage: serializeMessage(messageSnap),
      storage: 'firestore',
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Không thể lưu tin nhắn.',
      detail: error.message,
    });
  }
}

export async function listMessages(req, res) {
  try {
    const { roomId } = req.query;

    if (!roomId || !roomId.trim()) {
      return res.status(400).json({ message: 'Thiếu query param roomId.' });
    }

    const db = getFirestore();
    const roomSnap = await db.collection('rooms').doc(roomId.trim()).get();

    if (!roomSnap.exists) {
      return res.status(404).json({
        message: 'Room không tồn tại.',
        roomId: roomId.trim(),
      });
    }

    const snapshot = await db.collection('messages').where('roomId', '==', roomId.trim()).get();
    const chatMessages = snapshot.docs.map(serializeMessage).sort((a, b) => {
      const left = a.createdAt || '';
      const right = b.createdAt || '';
      return right.localeCompare(left);
    });

    return res.json({
      message: 'Lịch sử chat của room.',
      chatMessages,
      storage: 'firestore',
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Không thể lấy lịch sử chat.',
      detail: error.message,
    });
  }
}
