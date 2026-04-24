const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// Public Routes
router.post('/register', authController.register);
router.post('/login', authController.login);

// Protected Routes (requires Bearer token)
router.get('/profile', authMiddleware, authController.getProfile);

module.exports = router;
