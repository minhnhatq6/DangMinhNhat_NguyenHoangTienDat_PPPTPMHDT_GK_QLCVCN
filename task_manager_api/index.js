// index.js
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const taskRoutes = require('./routes/tasks');
const projectRoutes = require('./routes/projects');
const milestoneRoutes = require('./routes/milestones');
const app = express();
app.use(cors()); // dev: allow all
app.use(express.json());

// Connect MongoDB
const uri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/qlcv';
mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('✅ MongoDB connected'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

// Mount routes
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/milestones', milestoneRoutes);

// Quick root
app.get('/', (req, res) => res.send('Task Manager API is running 🚀'));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`✅ Server running on http://localhost:${PORT}`));
