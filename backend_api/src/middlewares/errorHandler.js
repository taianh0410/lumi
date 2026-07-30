export function errorHandler(error, _req, res, _next) {
  console.error(error);

  return res.status(500).json({
    message: 'Lỗi server không xác định.',
    detail: error.message,
  });
}
