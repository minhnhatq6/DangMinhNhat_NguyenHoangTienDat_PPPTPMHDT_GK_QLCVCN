const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Milestone = require('../models/Milestone');
const Project = require('../models/Project');
const Task = require('../models/Task');

// GET /api/milestones
router.get('/', auth, async (req, res) => {
  try {
    const query = { userId: req.user.id };
    if (req.query.project) {
      query.project = req.query.project;
    }
    const milestones = await Milestone.find(query)
      .populate('project', 'name colors')
      .sort({ date: 1, createdAt: -1 }); // Sắp xếp theo ngày
    res.json(milestones);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// POST /api/milestones
router.post('/', auth, async (req, res) => {
  try {
    // THAY ĐỔI: Chỉ nhận các trường cần thiết
    const { project, name, description, date } = req.body;
    if (!project || !name) return res.status(400).json({ message: 'Project và tên là bắt buộc' });

    const proj = await Project.findOne({ _id: project, userId: req.user.id });
    if (!proj) return res.status(404).json({ message: 'Project không tồn tại hoặc bạn không có quyền' });

    const m = new Milestone({
      userId: req.user.id,
      project,
      name,
      description: description || '',
      date: date ? new Date(date) : null,
    });
    await m.save();

    const populated = await Milestone.findById(m._id).populate('project', 'name colors');
    res.status(201).json(populated);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// PUT /api/milestones/:id
router.put('/:id', auth, async (req, res) => {
  try {
    const milestone = await Milestone.findOne({ _id: req.params.id, userId: req.user.id });
    if (!milestone) {
      return res.status(404).json({ message: 'Milestone không tồn tại hoặc bạn không có quyền' });
    }

    // THAY ĐỔI: Chỉ nhận các trường cần thiết
    const { project, name, description, date } = req.body;

    if (project !== undefined) milestone.project = project;
    if (name !== undefined) milestone.name = name;
    if (description !== undefined) milestone.description = description;
    if (date !== undefined) milestone.date = date ? new Date(date) : null;

    await milestone.save();
    const populated = await Milestone.findById(milestone._id).populate('project', 'name colors');
    res.json(populated);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// DELETE /api/milestones/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const milestone = await Milestone.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
    if (!milestone) {
      return res.status(404).json({ message: 'Milestone không tồn tại hoặc bạn không có quyền' });
    }
    // Bỏ liên kết milestone khỏi các task liên quan
    await Task.updateMany({ milestone: milestone._id }, { $set: { milestone: null } });
    res.json({ message: 'Đã xóa milestone' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

module.exports = router;