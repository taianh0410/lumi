import { Router } from 'express';

import aiRoutes from './aiRoutes.js';
import authRoutes from './authRoutes.js';
import chatRoutes from './chatRoutes.js';
import classRoutes from './classRoutes.js';
import friendRoutes from './friendRoutes.js';
import groupRoutes from './groupRoutes.js';
import healthRoutes from './healthRoutes.js';
import roomRoutes from './roomRoutes.js';
import messageRoutes from './messageRoutes.js';

const router = Router();

router.use('/health',       healthRoutes);
router.use('/api/auth',     authRoutes);
router.use('/api/chat',     chatRoutes);
router.use('/api/classes',  classRoutes);
router.use('/api/friends',  friendRoutes);
router.use('/api/groups',   groupRoutes);
router.use('/api',          aiRoutes);
router.use('/rooms',        roomRoutes);
router.use('/api/messages', messageRoutes);

export default router;
