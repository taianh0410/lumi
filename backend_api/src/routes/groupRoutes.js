import { Router } from 'express';

import { createGroup, getMyGroups, getOrCreateDirectGroup } from '../controllers/groupController.js';
import { authenticateRequest } from '../middlewares/authMiddleware.js';

const router = Router();

router.use(authenticateRequest);

router.post('/', createGroup);
router.post('/direct', getOrCreateDirectGroup);
router.get('/',  getMyGroups);

export default router;
