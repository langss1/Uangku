const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// Public Routes
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/login-2fa', authController.verify2FALogin);
router.post('/forgot-password', authController.forgotPassword);

// Protected Routes (requires Bearer token)
router.get('/profile', authMiddleware, authController.getProfile);
router.put('/profile', authMiddleware, authController.updateProfile);
router.put('/preferences', authMiddleware, authController.updatePreferences);
router.put('/security', authMiddleware, authController.updateSecurity);
router.post('/2fa/generate', authMiddleware, authController.generateTOTP);
router.post('/2fa/verify', authMiddleware, authController.verifyAndEnableTOTP);
router.post('/2fa/update-type', authMiddleware, authController.update2FAType);

module.exports = router;
