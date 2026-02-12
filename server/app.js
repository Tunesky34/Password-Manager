import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import passwordRoutes from './routes/passwordRoutes.js';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Backend is running',
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

// Routes
app.use('/api/passwords', passwordRoutes);

// Use PORT from environment or default to 5000
const PORT = process.env.PORT || 5000;

// Start server first
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🟢 Server running on port ${PORT}`);
});

// Then try to connect to MongoDB (non-blocking)
mongoose.connect(process.env.DATABASE_URL)
  .then(() => {
    console.log('🟢 Connected to MongoDB');
  })
  .catch(err => {
    console.error('❌ MongoDB error:', err.message);
    console.log('⚠️  Server running without database connection');
  });
