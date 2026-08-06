import dotenv from 'dotenv';
import { createServer } from 'node:http';

import { Server } from 'socket.io';

import app from './app.js';
import { Message } from './models/Message.js';

dotenv.config();

await import('./config/firebase.js');
const { connectDB } = await import('./config/db.js');

await connectDB();

const port = process.env.PORT || 3000;
const server = createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

io.on('connection', (socket) => {
  console.log(`Socket connected: ${socket.id}`);

  socket.on('join_group', (groupId) => {
    if (!groupId) {
      return;
    }

    socket.join(String(groupId));
    console.log(`User joined group: ${groupId}`);
  });

  socket.on('send_message', async (payload = {}) => {
    try {
      const { groupId, senderId, content } = payload;

      if (!groupId || !senderId || !content || !String(content).trim()) {
        socket.emit('message_error', { message: 'Thiếu groupId, senderId hoặc content.' });
        return;
      }

      const message = await Message.create({
        groupId,
        senderId,
        content: String(content).trim(),
      });

      const populatedMessage = await Message.findById(message._id).populate(
        'senderId',
        'username role',
      );

      io.to(String(groupId)).emit('receive_message', populatedMessage);
    } catch (error) {
      console.error('[SOCKET][SEND_MESSAGE]', error.message);
      socket.emit('message_error', {
        message: 'Không thể gửi tin nhắn.',
        detail: error.message,
      });
    }
  });

  socket.on('disconnect', (reason) => {
    console.log(`Socket disconnected: ${socket.id} (${reason})`);
  });
});

server.listen(port, () => {
  console.log(`backend-api listening on port ${port}`);
});
