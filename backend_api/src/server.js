import dotenv from 'dotenv';

dotenv.config();

const { default: app } = await import('./app.js');
await import('./config/firebase.js');
const { connectDB } = await import('./config/db.js');

await connectDB();

const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`backend-api listening on port ${port}`);
});
