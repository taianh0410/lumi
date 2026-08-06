import multer from 'multer';
import { createRequire } from 'module';
import { GoogleGenerativeAI } from '@google/generative-ai';

const require = createRequire(import.meta.url);
const pdf = require('pdf-parse');

import { Class } from '../models/Class.js';

const upload = multer({ storage: multer.memoryStorage() });

const EXTRACT_PROMPT = `Bạn là một chuyên gia phân tích giáo trình Vật lý THPT.
Hãy đọc nội dung bài giảng sau và trích xuất tối đa 5 chủ đề/khái niệm Vật lý cốt lõi.
BẮT BUỘC chỉ trả về một mảng JSON hợp lệ chứa các chuỗi (Ví dụ: ["Điện trường", "Định luật Coulomb", "Công của lực điện"]).
Không kèm markdown, không giải thích thêm.`;

function getCurrentUserId(req) {
  return req.user?.id ?? req.user?.uid ?? req.user?.userId ?? null;
}

function safeParseTagArray(raw) {
  // Xóa markdown code fence nếu Gemini bọc trong ```json ... ```
  const cleaned = raw.replace(/```json\s*/gi, '').replace(/```\s*/g, '').trim();
  const parsed = JSON.parse(cleaned);
  if (!Array.isArray(parsed)) throw new Error('Gemini không trả về mảng JSON.');
  return parsed.filter((t) => typeof t === 'string' && t.trim().length > 0);
}

// POST /api/classes/:classId/lessons
export async function createLesson(req, res) {
  try {
    const userId = getCurrentUserId(req);
    const { classId } = req.params;
    const { title, content = '', resourceUrl = '' } = req.body;

    if (!userId) {
      return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
    }
    if (!title || !String(title).trim()) {
      return res.status(400).json({ message: 'Thiếu tiêu đề bài học.' });
    }

    const classObj = await Class.findById(classId);
    if (!classObj) {
      return res.status(404).json({ message: 'Không tìm thấy lớp học.' });
    }

    if (String(classObj.teacherId) !== String(userId)) {
      return res.status(403).json({ message: 'Chỉ giáo viên mới có quyền tải lên.' });
    }

    const lesson = {
      title: String(title).trim(),
      content: String(content).trim(),
      resourceUrl: String(resourceUrl).trim(),
      classId: classObj._id,
      createdBy: userId,
      createdAt: new Date().toISOString(),
    };

    return res.status(201).json({ message: 'Tạo bài học thành công.', lesson });
  } catch (error) {
    console.error('[LESSON][CREATE]', error.message);
    return res.status(500).json({ message: 'Lỗi server.', detail: error.message });
  }
}

// POST /api/classes/:classId/upload  (multipart/form-data, field: file)
export function uploadMaterial(req, res) {
  upload.single('file')(req, res, async (err) => {
    if (err) {
      console.error('[LESSON][UPLOAD] multer error:', err.message);
      return res.status(400).json({ message: 'Lỗi nhận file.', detail: err.message });
    }

    try {
      const userId = getCurrentUserId(req);
      const { classId } = req.params;

      if (!userId) {
        return res.status(401).json({ message: 'Không xác định được người dùng hiện tại.' });
      }
      if (!req.file) {
        return res.status(400).json({ message: 'Thiếu file PDF.' });
      }
      if (!req.file.originalname?.toLowerCase().endsWith('.pdf')) {
        return res.status(400).json({ message: 'Chỉ chấp nhận file PDF.' });
      }

      const targetClass = await Class.findById(classId);
      if (!targetClass) {
        return res.status(404).json({ message: 'Không tìm thấy lớp học.' });
      }
      if (String(targetClass.teacherId) !== String(userId)) {
        return res.status(403).json({ message: 'Chỉ giáo viên mới có quyền tải lên.' });
      }

      // ── Trích xuất text từ PDF ────────────────────────────────────────────
      const pdfData = await pdf(req.file.buffer);
      const extractedText = pdfData.text.slice(0, 10000);

      if (!extractedText.trim()) {
        return res.status(422).json({ message: 'Không trích xuất được văn bản từ PDF.' });
      }

      // ── Gọi Gemini API bóc tách mảng kiến thức ───────────────────────────
      const apiKey = process.env.GEMINI_API_KEY;
      if (!apiKey) {
        return res.status(500).json({ message: 'GEMINI_API_KEY chưa được cấu hình.' });
      }

      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({
        model: process.env.GEMINI_MODEL || 'gemini-2.0-flash',
      });

      const prompt = `${EXTRACT_PROMPT}\n\nNội dung tài liệu:\n${extractedText}`;
      const geminiResult = await model.generateContent(prompt);
      const rawText = geminiResult.response.text();

      let newTags = [];
      try {
        newTags = safeParseTagArray(rawText);
      } catch (parseErr) {
        console.warn('[LESSON][UPLOAD] JSON parse failed, raw:', rawText);
        // Không crash — trả về danh sách rỗng nhưng vẫn upload thành công
      }

      // ── Merge tags vào Class, chống trùng lặp ───────────────────────────
      const mergedTags = [...new Set([...targetClass.knowledgeTags, ...newTags])];
      targetClass.knowledgeTags = mergedTags;
      await targetClass.save();

      console.log(`[LESSON][UPLOAD] classId=${classId} tags:`, mergedTags);

      return res.status(200).json({
        message: 'Upload và phân tích thành công.',
        fileName: req.file.originalname,
        extractedTags: newTags,
        allTags: mergedTags,
      });
    } catch (error) {
      console.error('[LESSON][UPLOAD]', error.message);
      return res.status(500).json({ message: 'Lỗi server khi xử lý tài liệu.', detail: error.message });
    }
  });
}
