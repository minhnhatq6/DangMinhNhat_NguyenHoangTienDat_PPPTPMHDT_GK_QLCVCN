// task_manager_api/models/Project.js
const mongoose = require('mongoose');

const ProjectSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  colors: { type: [String], default: ['#2196F3'] },
  description: { type: String, default: '' }
}, { timestamps: true });

module.exports = mongoose.model('Project', ProjectSchema);
