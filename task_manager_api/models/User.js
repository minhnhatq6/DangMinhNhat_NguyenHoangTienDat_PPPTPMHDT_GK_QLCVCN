// task_manager_api/models/User.js
const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  passwordHash: { type: String, required: true },
  displayName: { type: String, default: '' },
  settings: {
    theme: { type: String, enum: ['light', 'dark'], default: 'light' },
    remindersEnabled: { type: Boolean, default: true },
    reminderSound: { type: Boolean, default: true }
  }
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);
