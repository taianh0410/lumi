import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

import { User } from '../models/User.js';

const BCRYPT_ROUNDS = 12;
const JWT_EXPIRY = '7d';

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('JWT_SECRET không được cấu hình trong .env');
  return secret;
}

export async function register(req, res) {
  try {
    const { username, password, role } = req.body;

    if (!username || !String(username).trim()) {
      return res.status(400).json({ message: 'Thiếu username.' });
    }
    if (!password || String(password).length < 6) {
      return res.status(400).json({ message: 'Password phải có ít nhất 6 ký tự.' });
    }

    const normalizedRole = role === 'teacher' ? 'teacher' : 'student';
    const normalizedUsername = String(username).trim().toLowerCase();

    const exists = await User.findOne({ username: normalizedUsername });
    if (exists) {
      return res.status(409).json({ message: 'Username đã tồn tại.' });
    }

    const hashedPassword = await bcrypt.hash(String(password), BCRYPT_ROUNDS);
    const user = await User.create({
      username: normalizedUsername,
      password: hashedPassword,
      role: normalizedRole,
    });

    return res.status(201).json({
      message: 'Đăng ký thành công.',
      user: { id: user._id, username: user.username, role: user.role },
    });
  } catch (error) {
    console.error('[AUTH][REGISTER]', error.message);
    return res.status(500).json({ message: 'Lỗi server khi đăng ký.', detail: error.message });
  }
}

export async function login(req, res) {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ message: 'Thiếu username hoặc password.' });
    }

    const normalizedUsername = String(username).trim().toLowerCase();
    const user = await User.findOne({ username: normalizedUsername });

    if (!user || !(await bcrypt.compare(String(password), user.password))) {
      return res.status(401).json({ message: 'Username hoặc password không đúng.' });
    }

    const token = jwt.sign(
      { id: user._id, username: user.username, role: user.role },
      getJwtSecret(),
      { expiresIn: JWT_EXPIRY },
    );

    return res.status(200).json({
      message: 'Đăng nhập thành công.',
      token,
      user: { id: user._id, username: user.username, role: user.role },
    });
  } catch (error) {
    console.error('[AUTH][LOGIN]', error.message);
    return res.status(500).json({ message: 'Lỗi server khi đăng nhập.', detail: error.message });
  }
}

export async function me(req, res) {
  return res.status(200).json({ user: req.user });
}
