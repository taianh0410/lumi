import { Router } from 'express';

import { createMessage, listMessages } from '../controllers/messageController.js';
import { authenticateRequest } from '../middlewares/authMiddleware.js';
import { requireRole } from '../middlewares/rbacMiddleware.js';

const router = Router();

router.get('/', authenticateRequest, requireRole('student', 'room_admin'), listMessages);
router.post('/', authenticateRequest, requireRole('student', 'room_admin'), createMessage);

export default router;
