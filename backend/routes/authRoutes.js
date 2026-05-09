const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// Public Routes
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/login-2fa', authController.login2FA);

// Protected Routes (requires Bearer token)
router.get('/profile', authMiddleware, authController.getProfile);
router.put('/profile', authMiddleware, authController.updateProfile);
router.put('/security', authMiddleware, authController.updateSecurity);
router.post('/2fa/generate', authMiddleware, authController.generate2FA);
router.post('/2fa/verify', authMiddleware, authController.verify2FA);

module.exports = router;
