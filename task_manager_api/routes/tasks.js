const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Task = require('../models/Task');

const toInt = (v, fallback) => {
  const n = parseInt(v);
  return Number.isNaN(n) ? fallback : n;
};

// GET /api/tasks (Đã bỏ filter 'archived')
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const { search, status, project, category, priority, from, to, sort, page = 1, limit = 100 } = req.query;
    const q = { userId };
    if (status === 'done') q.isDone = true;
    else if (status === 'pending') q.isDone = false;
    if (project) q.project = project;
    if (category) q.category = category;
    if (priority !== undefined) q.priority = toInt(priority, undefined);
    if (search) {
      const rx = new RegExp(search, 'i');
      q.$or = [{ title: rx }, { note: rx }]; // Bỏ tags khỏi search
    }
    if (from || to) {
      q.dueDate = {};
      if (from) q.dueDate.$gte = new Date(from);
      if (to) q.dueDate.$lte = new Date(to);
    }
    let sortObj = { dueDate: 1, createdAt: -1 };
    if (sort === 'priority') sortObj = { priority: -1, dueDate: 1 };
    if (sort === 'createdAt') sortObj = { createdAt: -1 };
    const pg = Math.max(1, parseInt(page));
    const lim = Math.max(1, Math.min(1000, parseInt(limit)));
    const skip = (pg - 1) * lim;

    const tasks = await Task.find(q)
      .populate('project', 'name colors')
      .sort(sortObj)
      .skip(skip)
      .limit(lim);
    res.json(tasks);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// POST /api/tasks -> create (Đã dọn dẹp)
router.post('/', auth, async (req, res) => {
  try {
    const { title, note, dueDate, priority, project, category, progress } = req.body;
    if (!title) return res.status(400).json({ message: 'Title là bắt buộc' });
    const t = new Task({
        userId: req.user.id,
        title,
        note: note || '',
        dueDate: dueDate ? new Date(dueDate) : null,
        priority: typeof priority === 'number' ? priority : 1,
        project: project || null,
        category: category || '',
        progress: progress || 0,
    });
    await t.save();
    const populated = await Task.findById(t._id).populate('project', 'name colors');
    res.status(201).json(populated);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// PUT /api/tasks/:id -> update (Đã bỏ 'archived')
router.put('/:id', auth, async (req, res) => {
  try {
    const task = await Task.findOne({ _id: req.params.id, userId: req.user.id });
    if (!task) return res.status(404).json({ message: 'Task không tồn tại' });

    const { title, note, dueDate, isDone, progress, priority, project, category } = req.body;

    if (title !== undefined) task.title = title;
    if (note !== undefined) task.note = note;
    if (dueDate !== undefined) task.dueDate = dueDate ? new Date(dueDate) : null;
    if (isDone !== undefined) {
      task.isDone = !!isDone;
      task.completedAt = task.isDone ? new Date() : null;
    }
    if (progress !== undefined) task.progress = Math.max(0, Math.min(100, progress));
    if (priority !== undefined) task.priority = priority;
    if (project !== undefined) task.project = project || null;
    if (category !== undefined) task.category = category;

    await task.save();
    const populated = await Task.findById(task._id).populate('project', 'name colors');
    res.json(populated);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// POST /api/tasks/:id/complete (Giữ nguyên)
router.post('/:id/complete', auth, async (req, res) => { /* ... */ });

// --- ROUTE /archive ĐÃ BỊ XÓA BỎ ---

// GET /api/tasks/calendar (Giữ nguyên)
router.get('/calendar', auth, async (req, res) => { /* ... */ });

// GET /api/tasks/stats (Đã bỏ 'archived')
router.get('/stats', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const mongoose = require('mongoose');

    const total = await Task.countDocuments({ userId });
    const completed = await Task.countDocuments({ userId, isDone: true });
    const overdue = await Task.countDocuments({ userId, isDone: false, dueDate: { $lt: new Date() } });

    const byPriorityAgg = await Task.aggregate([
      { $match: { userId: mongoose.Types.ObjectId(userId) } },
      { $group: { _id: '$priority', count: { $sum: 1 } } }
    ]);
    const byPriority = byPriorityAgg.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {});

    res.json({
      total,
      completed,
      pending: total - completed,
      overdue,
      byPriority: {
        high: byPriority[2] || 0,
        normal: byPriority[1] || 0,
        low: byPriority[0] || 0,
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// DELETE /api/tasks/:id (Giữ nguyên)
router.delete('/:id', auth, async (req, res) => { /* ... */ });

module.exports = router;