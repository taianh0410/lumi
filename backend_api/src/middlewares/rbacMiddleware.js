const allowedRoles = ['student', 'room_admin'];

export function requireRole(...roles) {
  const normalizedRoles = roles.length > 0 ? roles : allowedRoles;

  return (req, res, next) => {
    try {
      const currentRole = req.user?.role;

      if (!currentRole) {
        return res.status(401).json({ message: 'Người dùng chưa được xác thực.' });
      }

      if (!normalizedRoles.includes(currentRole)) {
        return res.status(403).json({
          message: 'Không đủ quyền truy cập.',
          requiredRoles: normalizedRoles,
          currentRole,
        });
      }

      return next();
    } catch (error) {
      return res.status(500).json({
        message: 'Lỗi RBAC middleware.',
        detail: error.message,
      });
    }
  };
}
