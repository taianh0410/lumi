import jwt from 'jsonwebtoken';

import { getAuth, isFirebaseReady } from '../config/firebase.js';

const MOCK_AUTH_ENABLED = () =>
  String(process.env.MOCK_AUTH_ENABLED || 'false').toLowerCase() === 'true';

function extractBearerToken(req) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  return scheme === 'Bearer' && token ? token : null;
}

/** Verify local JWT issued by /api/auth/login */
function verifyLocalJwt(token) {
  const secret = process.env.JWT_SECRET;
  if (!secret) return null;

  try {
    const decoded = jwt.verify(token, secret);
    return {
      uid: decoded.id,
      userId: decoded.id,
      username: decoded.username,
      role: decoded.role || 'student',
      source: 'local-jwt',
    };
  } catch {
    return null;
  }
}

/** Verify Firebase ID token */
async function verifyFirebaseToken(token) {
  if (!isFirebaseReady()) return null;
  try {
    const decoded = await getAuth().verifyIdToken(token);
    return {
      uid: decoded.uid,
      userId: decoded.uid,
      email: decoded.email,
      role: decoded.role || decoded.customClaims?.role || 'student',
      source: 'firebase',
    };
  } catch {
    return null;
  }
}

export async function authenticateRequest(req, res, next) {
  try {
    // 1. Mock auth for local Postman testing
    if (MOCK_AUTH_ENABLED()) {
      const mockId = req.headers['x-mock-user-id'];
      const mockRole = req.headers['x-mock-user-role'];
      if (mockId && mockRole) {
        req.user = { uid: mockId, userId: mockId, role: mockRole, source: 'mock' };
        return next();
      }
    }

    // 2. Extract Bearer token
    const token = extractBearerToken(req);
    if (!token) {
      return res.status(401).json({
        message: 'Thiếu Bearer token. Đăng nhập tại POST /api/auth/login để lấy token.',
      });
    }

    // 3. Try local JWT first (faster, no network), then Firebase
    const user = verifyLocalJwt(token) || (await verifyFirebaseToken(token));

    if (!user) {
      return res.status(401).json({ message: 'Token không hợp lệ hoặc đã hết hạn.' });
    }

    req.user = user;
    return next();
  } catch (error) {
    return res.status(401).json({ message: 'Xác thực thất bại.', detail: error.message });
  }
}

/** Alias kept for backward compatibility */
export const verifyToken = authenticateRequest;
