import { Router } from 'express';

import { createSession, sendMessage, getHistory } from '../controllers/chatController.js';
import { authenticateRequest } from '../middlewares/authMiddleware.js';

const router = Router();

// Tất cả route đều yêu cầu JWT hợp lệ
router.use(authenticateRequest);

router.post('/session',              createSession);
router.post('/message',              sendMessage);
router.get('/session/:sessionId',    getHistory);

export default router;
