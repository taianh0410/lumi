import { Router } from 'express';

import aiRoutes from './aiRoutes.js';
import authRoutes from './authRoutes.js';
import chatRoutes from './chatRoutes.js';
import healthRoutes from './healthRoutes.js';
import roomRoutes from './roomRoutes.js';
import messageRoutes from './messageRoutes.js';

const router = Router();

router.use('/health', healthRoutes);
router.use('/api/auth', authRoutes);
router.use('/api/chat', chatRoutes);
router.use('/api', aiRoutes);
router.use('/rooms', roomRoutes);
router.use('/messages', messageRoutes);

export default router;
