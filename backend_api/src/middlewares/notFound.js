export function notFoundHandler(_req, res) {
  return res.status(404).json({
    message: 'Route không tồn tại.',
  });
}
