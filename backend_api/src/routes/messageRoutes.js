import { Router } from 'express';

import { authenticateRequest } from '../middlewares/authMiddleware.js';
import { getMessagesByGroup } from '../controllers/messageController.js';

const router = Router();

router.get('/:groupId', authenticateRequest, getMessagesByGroup);

export default router;
