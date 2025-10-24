const mongoose = require('mongoose');

const MilestoneSchema = new mongoose.Schema({
  // --- LIÊN KẾT BẮT BUỘC ---
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  project: { type: mongoose.Schema.Types.ObjectId, ref: 'Project', required: true, index: true },

  // --- THÔNG TIN CƠ BẢN ---
  name: { type: String, required: true },
  description: { type: String, default: '' },

  // --- THỜI GIAN (ĐÃ THAY ĐỔI) ---
  // Chỉ còn một ngày duy nhất để đánh dấu sự kiện
  date: { type: Date, default: null },

}, { timestamps: true });

// Bỏ completed, completedAt, priority, startDate, endDate, progress


// Thêm index để tối ưu truy vấn
MilestoneSchema.index({ userId: 1, project: 1 });

module.exports = mongoose.model('Milestone', MilestoneSchema);