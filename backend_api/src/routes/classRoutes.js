import { Router } from 'express';

import { createClass, getMyClasses, joinClass } from '../controllers/classController.js';
import { createLesson, uploadMaterial } from '../controllers/lessonController.js';
import { handleSocraticChat } from '../controllers/classAiController.js';
import { getHeatmapData } from '../controllers/analyticsController.js';
import { authenticateRequest } from '../middlewares/authMiddleware.js';

const router = Router();

router.use(authenticateRequest);

router.post('/',                     createClass);
router.get('/mine',                  getMyClasses);
router.post('/join',                 joinClass);
router.post('/:classId/lessons',     createLesson);
router.post('/:classId/upload',      uploadMaterial);
router.post('/:classId/socratic',    handleSocraticChat);
router.get('/:classId/heatmap',      getHeatmapData);

export default router;
