import { Router } from 'express';

import {
	getFriends,
	getPendingRequests,
	sendRequest,
	acceptRequest,
} from '../controllers/friendController.js';
import { authenticateRequest } from '../middlewares/authMiddleware.js';

const router = Router();

router.get('/list', authenticateRequest, getFriends);
router.get('/pending', authenticateRequest, getPendingRequests);
router.post('/request', authenticateRequest, sendRequest);
router.post('/accept', authenticateRequest, acceptRequest);

export default router;
