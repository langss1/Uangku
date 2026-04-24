const express = require('express');
const router = express.Router();
const apiController = require('../controllers/apiController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/dashboard', apiController.getDashboard);
router.get('/transactions', apiController.getTransactions);
router.post('/transactions', apiController.addTransaction);
router.get('/notifications', apiController.getNotifications);

module.exports = router;
