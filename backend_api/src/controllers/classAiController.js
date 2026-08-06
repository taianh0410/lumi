import { GoogleGenerativeAI } from '@google/generative-ai';

import { Class } from '../models/Class.js';

const SOCRATIC_SYSTEM_PROMPT = `Bạn là một gia sư Vật lý tận tâm, chuyên hỗ trợ học sinh THPT (Lớp 11 và 12).
Bắt buộc áp dụng phương pháp Socratic: KHÔNG BAO GIỜ giải bài hay đưa ra đáp án trực tiếp.
Hãy phân tích câu hỏi của học sinh, xác định khái niệm cốt lõi (ví dụ: bảo toàn năng lượng, khúc xạ ánh sáng, điện trường...), và đặt một hoặc hai câu hỏi gợi mở để dẫn dắt học sinh tự suy nghĩ bước tiếp theo.
Giữ thái độ thân thiện, khích lệ và dùng ngôn ngữ dễ hiểu.`;

function getGeminiModel() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY chưa được cấu hình trong .env');
  }
  const genAI = new GoogleGenerativeAI(apiKey);
  return genAI.getGenerativeModel({
    model: process.env.GEMINI_MODEL || 'gemini-2.0-flash',
    systemInstruction: SOCRATIC_SYSTEM_PROMPT,
  });
}

// POST /api/classes/:classId/socratic
// Body: { message }
export async function handleSocraticChat(req, res) {
  try {
    const { classId } = req.params;
    const { message } = req.body;

    if (!message || !String(message).trim()) {
      return res.status(400).json({ message: 'Thiếu nội dung câu hỏi.' });
    }

    const classObj = await Class.findById(classId);
    if (!classObj) {
      return res.status(404).json({ message: 'Không tìm thấy lớp học.' });
    }

    const model = getGeminiModel();
    const result = await model.generateContent(String(message).trim());
    const answer = result.response.text();

    return res.status(200).json({
      answer,
      classId,
      sender: 'ai',
    });
  } catch (error) {
    console.error('[CLASS_AI][SOCRATIC]', error.message);
    return res.status(500).json({
      message: 'Gia sư AI đang nghỉ ngơi chút, bạn thử lại sau nhé!',
      detail: error.message,
    });
  }
}
