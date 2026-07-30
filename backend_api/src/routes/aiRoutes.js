import { Router } from 'express';

import { proxyChat, proxyUpload } from '../controllers/aiController.js';
import { authenticateRequest } from '../middlewares/authMiddleware.js';
import { requireRole } from '../middlewares/rbacMiddleware.js';
import { uploadSinglePdf } from '../middlewares/uploadMiddleware.js';

const router = Router();

router.post('/chat', authenticateRequest, requireRole('student', 'room_admin'), proxyChat);
router.post(
  '/upload',
  authenticateRequest,
  requireRole('student', 'room_admin'),
  uploadSinglePdf.single('file'),
  proxyUpload,
);

export default router;
