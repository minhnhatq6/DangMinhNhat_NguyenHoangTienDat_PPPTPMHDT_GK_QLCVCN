const mongoose = require('mongoose');

const TaskSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  note: { type: String, default: '' },
  dueDate: { type: Date, default: null },
  isDone: { type: Boolean, default: false },
  completedAt: { type: Date, default: null },
  progress: { type: Number, default: 0, min: 0, max: 100 },
  priority: { type: Number, default: 1 }, // 0: low, 1: normal, 2: high
  project: { type: mongoose.Schema.Types.ObjectId, ref: 'Project', default: null },
  category: { type: String, default: '' },
}, { timestamps: true });

TaskSchema.index({ userId: 1, dueDate: 1 });

module.exports = mongoose.model('Task', TaskSchema);