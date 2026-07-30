import multer from 'multer';

const storage = multer.memoryStorage();

export const uploadSinglePdf = multer({
  storage,
  limits: {
    fileSize: 25 * 1024 * 1024,
  },
});
