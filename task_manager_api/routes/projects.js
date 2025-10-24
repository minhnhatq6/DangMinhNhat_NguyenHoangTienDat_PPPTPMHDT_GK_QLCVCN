const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Project = require('../models/Project');

// GET /api/projects - KHÔNG THAY ĐỔI
router.get('/', auth, async (req, res) => {
  try {
    const projects = await Project.find({ userId: req.user.id }).sort({ createdAt: -1 });
    res.json(projects);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// POST /api/projects - PHIÊN BẢN SỬA LỖI
router.post('/', auth, async (req, res) => {
  try {
    // 1. Đọc đúng biến 'colors' từ body
    const { name, colors, description } = req.body;
    if (!name) return res.status(400).json({ message: 'Tên project là bắt buộc' });

    // 2. Tạo một đối tượng để chứa dữ liệu một cách an toàn
    const newProjectData = {
      userId: req.user.id,
      name,
      description: description || ''
    };

    // 3. Kiểm tra và gán mảng 'colors' một cách có điều kiện
    // Điều này đảm bảo rằng chúng ta chỉ gán 'colors' nếu nó là một mảng hợp lệ được gửi từ client
    if (Array.isArray(colors) && colors.length > 0) {
      newProjectData.colors = colors;
    }
    // Nếu client không gửi 'colors', Mongoose Model sẽ tự động dùng giá trị default là ['#2196F3']

    // 4. Tạo Project mới từ đối tượng newProjectData đã được chuẩn bị kỹ lưỡng
    const p = new Project(newProjectData);
    await p.save();
    res.status(201).json(p);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});



// PUT /api/projects/:id - ĐÃ SỬA
router.put('/:id', auth, async (req, res) => {
  try {
    const project = await Project.findOne({ _id: req.params.id, userId: req.user.id });
    if (!project) return res.status(404).json({ message: 'Project không tồn tại' });

    // THAY ĐỔI: Nhận 'colors' thay vì 'color'
    const { name, colors, description } = req.body;
    if (name !== undefined) project.name = name;
    if (colors !== undefined) project.colors = colors; // THAY ĐỔI Ở ĐÂY
    if (description !== undefined) project.description = description;
    
    await project.save();
    res.json(project);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// DELETE /api/projects/:id - KHÔNG THAY ĐỔI
router.delete('/:id', auth, async (req, res) => {
  try {
    const project = await Project.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
    if (!project) return res.status(404).json({ message: 'Project không tồn tại' });

    // remove milestones that belong to this project
    const Milestone = require('../models/Milestone');
    await Milestone.deleteMany({ project: project._id });

    // unset project from tasks (keep tasks)
    const Task = require('../models/Task');
    await Task.updateMany({ project: project._id }, { $set: { project: null } });

    res.json({ message: 'Đã xóa' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});




module.exports = router;