import { getFirestore } from '../config/firebase.js';


function serializeRoom(doc) {
  return {
    id: doc.id,
    ...doc.data(),
  };
}

export async function createRoom(req, res) {
  try {
    const { name } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ message: 'Thiếu trường name của room.' });
    }

    const roomPayload = {
      name: name.trim(),
      userId: req.user.userId || req.user.uid,
      createdByRole: req.user.role,
      memberCount: 1,
      members: [
        {
          userId: req.user.userId || req.user.uid,
          role: req.user.role,
          joinedAt: new Date().toISOString(),
        },
      ],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const db = getFirestore();
    const roomRef = await db.collection('rooms').add(roomPayload);
    const roomSnap = await roomRef.get();

    return res.status(201).json({
      message: 'Tạo room thành công.',
      room: serializeRoom(roomSnap),
      storage: 'firestore',
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Không thể tạo room.',
      detail: error.message,
    });
  }
}

export async function listRooms(_req, res) {
  try {
    const db = getFirestore();
    const snapshot = await db.collection('rooms').orderBy('createdAt', 'desc').get();
    const rooms = snapshot.docs.map(serializeRoom);

    return res.json({
      message: 'Danh sách room.',
      rooms,
      storage: 'firestore',
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Không thể lấy danh sách room.',
      detail: error.message,
    });
  }
}
