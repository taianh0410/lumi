import { Class } from '../models/Class.js';

function getCurrentUserId(req) {
  return req.user?.id ?? req.user?.uid ?? req.user?.userId ?? null;
}

function generateJoinCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // loại bỏ ký tự dễ nhầm O/0/I/1
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

async function uniqueJoinCode() {
  let code;
  let attempts = 0;
  do {
    code = generateJoinCode();
    attempts++;
    if (attempts > 20) throw new Error('Không thể tạo mã lớp duy nhất.');
  } while (await Class.exists({ joinCode: code }));
  return code;
}

// POST /api/classes
export async function createClass(req, res) {
  try {
    const teacherId = getCurrentUserId(req);
    const { name, description = '', coverImage = '' } = req.body;

    if (!teacherId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }
    if (!name || !String(name).trim()) {
      return res.status(400).json({ message: 'Thiếu tên lớp.' });
    }

    const joinCode = await uniqueJoinCode();

    const createdClass = await Class.create({
      name: String(name).trim(),
      description: String(description || '').trim(),
      coverImage: String(coverImage || '').trim(),
      teacherId,
      students: [],
      joinCode,
    });

    const populated = await Class.findById(createdClass._id)
      .populate('teacherId', 'username')
      .populate('students', 'username role');

    return res.status(201).json({
      message: 'Tạo lớp thành công.',
      class: populated,
    });
  } catch (error) {
    console.error('[CLASS][CREATE]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}

// GET /api/classes/mine
export async function getMyClasses(req, res) {
  try {
    const userId = getCurrentUserId(req);

    if (!userId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }

    const classes = await Class.find({
      $or: [{ teacherId: userId }, { students: userId }],
    })
      .populate('teacherId', 'username')
      .populate('students', 'username role')
      .sort({ createdAt: -1 });

    return res.status(200).json({ classes });
  } catch (error) {
    console.error('[CLASS][GET_MY]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}

// POST /api/classes/join  — body: { joinCode }
export async function joinClass(req, res) {
  try {
    const userId = getCurrentUserId(req);
    const { joinCode } = req.body;

    if (!userId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }
    if (!joinCode || !String(joinCode).trim()) {
      return res.status(400).json({ message: 'Thiếu mã lớp (joinCode).' });
    }

    const targetClass = await Class.findOne({
      joinCode: String(joinCode).trim().toUpperCase(),
    });

    if (!targetClass) {
      return res.status(404).json({ message: 'Mã lớp không tồn tại hoặc không hợp lệ.' });
    }

    if (String(targetClass.teacherId) === String(userId)) {
      return res.status(200).json({ message: 'Bạn là giáo viên của lớp này.', class: targetClass });
    }

    if (targetClass.students.some((id) => String(id) === String(userId))) {
      return res.status(409).json({ message: 'Bạn đã là thành viên của lớp này.' });
    }

    targetClass.students.push(userId);
    await targetClass.save();

    const populated = await Class.findById(targetClass._id)
      .populate('teacherId', 'username')
      .populate('students', 'username role');

    return res.status(200).json({ message: 'Tham gia lớp thành công.', class: populated });
  } catch (error) {
    console.error('[CLASS][JOIN]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}
