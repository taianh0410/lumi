import { forwardChatToAiEngine, forwardUploadToAiEngine, getAiEngineUrl } from '../services/aiEngineClient.js';

function logConnectionError(action, error) {
  console.error(`[AI_ENGINE][${action}] Cannot reach Python service at ${getAiEngineUrl()}`);
  if (error.detail) {
    console.error(`[AI_ENGINE][${action}] Detail:`, error.detail);
  }
  console.error(error);
}

export async function proxyChat(req, res) {
  try {
    const { question, room_id = null, top_k = 5 } = req.body;

    if (!question || !String(question).trim()) {
      return res.status(400).json({ message: 'Thiếu question.' });
    }

    // Lấy user_id từ token đã xác thực thay vì tin tưởng body
    const user_id = req.user?.userId || null;

    const payload = {
      question: String(question).trim(),
      room_id,
      user_id,
      top_k,
    };

    const response = await forwardChatToAiEngine(payload);

    if (response.status >= 400) {
      return res.status(response.status).json({
        message: 'AI Engine trả lỗi khi xử lý chat.',
        detail: response.data,
      });
    }

    return res.status(200).json({
      message: 'Lumi response received.',
      ...response.data,
    });
  } catch (error) {
    const isConnectionError = error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT';
    if (isConnectionError) {
      logConnectionError('CHAT', error);
      return res.status(503).json({
        message: 'Không kết nối được tới ai_engine ở cổng 8000.',
        detail: 'Hãy kiểm tra Python service đang chạy trên http://127.0.0.1:8000',
      });
    }

    logConnectionError('CHAT', error);
    return res.status(500).json({
      message: 'Lỗi khi proxy chat sang ai_engine.',
      detail: error.detail || error.message,
    });
  }
}

export async function proxyUpload(req, res) {
  try {
    const file = req.file;
    const { room_id = null } = req.body;

    // Lấy user_id từ token đã xác thực
    const user_id = req.user?.userId || null;

    if (!file) {
      return res.status(400).json({ message: 'Thiếu file PDF upload.' });
    }

    if (!file.originalname?.toLowerCase().endsWith('.pdf')) {
      return res.status(400).json({ message: 'Chỉ chấp nhận file PDF.' });
    }

    const response = await forwardUploadToAiEngine(file, { room_id, user_id });

    if (response.status >= 400) {
      return res.status(response.status).json({
        message: 'AI Engine trả lỗi khi xử lý upload.',
        detail: response.data,
      });
    }

    return res.status(200).json({
      message: 'Upload và indexing thành công.',
      ...response.data,
    });
  } catch (error) {
    const isConnectionError = error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT';
    if (isConnectionError) {
      logConnectionError('UPLOAD', error);
      return res.status(503).json({
        message: 'Không kết nối được tới ai_engine ở cổng 8000.',
        detail: 'Hãy kiểm tra Python service đang chạy trên http://127.0.0.1:8000',
      });
    }

    logConnectionError('UPLOAD', error);
    return res.status(500).json({
      message: 'Lỗi khi proxy upload sang ai_engine.',
      detail: error.detail || error.message,
    });
  }
}
