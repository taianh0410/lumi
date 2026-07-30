import { Router } from 'express';

import { createRoom, listRooms } from '../controllers/roomController.js';
import { authenticateRequest } from '../middlewares/authMiddleware.js';
import { requireRole } from '../middlewares/rbacMiddleware.js';

const router = Router();

router.get('/', authenticateRequest, requireRole('student', 'room_admin'), listRooms);
router.post('/', authenticateRequest, requireRole('room_admin'), createRoom);

export default router;
