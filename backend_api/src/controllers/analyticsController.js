import { Class } from '../models/Class.js';

const DEFAULT_TAGS = ['Lực tĩnh điện', 'Dao động cơ', 'Sóng âm', 'Điện trường', 'Quang hình học'];

// GET /api/classes/:classId/heatmap
export async function getHeatmapData(req, res) {
  try {
    const { classId } = req.params;

    const classObj = await Class.findById(classId)
      .populate('students', '_id username');

    if (!classObj) {
      return res.status(404).json({ message: 'Không tìm thấy lớp học.' });
    }

    const tags = classObj.knowledgeTags?.length > 0
      ? classObj.knowledgeTags
      : DEFAULT_TAGS;

    const students = classObj.students.map((s) => ({
      id: s._id.toString(),
      username: s.username,
    }));

    // Sinh ma trận điểm ngẫu nhiên: matrix[studentId][tag] = 0..100
    const matrix = {};
    for (const student of students) {
      matrix[student.id] = {};
      for (const tag of tags) {
        matrix[student.id][tag] = Math.floor(Math.random() * 101);
      }
    }

    return res.status(200).json({ tags, students, matrix });
  } catch (error) {
    console.error('[ANALYTICS][HEATMAP]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}
