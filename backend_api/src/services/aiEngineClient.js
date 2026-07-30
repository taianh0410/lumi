import axios from 'axios';
import FormData from 'form-data';

const AI_ENGINE_URL = process.env.AI_ENGINE_URL || 'http://127.0.0.1:8000';
const AI_ENGINE_TIMEOUT_MS = Number(process.env.AI_ENGINE_TIMEOUT_MS || 60000);

function buildErrorDetail(error) {
  if (error.response) {
    return {
      status: error.response.status,
      data: error.response.data,
    };
  }

  return {
    message: error.message,
    code: error.code,
  };
}

export async function forwardChatToAiEngine(payload) {
  try {
    const response = await axios.post(`${AI_ENGINE_URL}/api/chat`, payload, {
      timeout: AI_ENGINE_TIMEOUT_MS,
      validateStatus: () => true,
    });

    return response;
  } catch (error) {
    error.detail = buildErrorDetail(error);
    throw error;
  }
}

export async function forwardUploadToAiEngine(file, fields) {
  const form = new FormData();
  form.append('file', file.buffer, {
    filename: file.originalname,
    contentType: file.mimetype || 'application/pdf',
  });

  if (fields.room_id) {
    form.append('room_id', fields.room_id);
  }

  if (fields.user_id) {
    form.append('user_id', fields.user_id);
  }

  try {
    const response = await axios.post(`${AI_ENGINE_URL}/api/upload`, form, {
      timeout: AI_ENGINE_TIMEOUT_MS,
      headers: form.getHeaders(),
      maxBodyLength: Infinity,
      maxContentLength: Infinity,
      validateStatus: () => true,
    });

    return response;
  } catch (error) {
    error.detail = buildErrorDetail(error);
    throw error;
  }
}

export function getAiEngineUrl() {
  return AI_ENGINE_URL;
}
