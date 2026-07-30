export function getHealth(_req, res) {
  try {
    return res.json({
      status: 'ok',
      service: 'backend-api',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Không thể lấy trạng thái health.',
      detail: error.message,
    });
  }
}
