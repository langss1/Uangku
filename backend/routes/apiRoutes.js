const express = require('express');
const router = express.Router();
const apiController = require('../controllers/apiController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/dashboard', apiController.getDashboard);
router.get('/transactions', apiController.getTransactions);
router.post('/transactions', apiController.addTransaction);
router.get('/notifications', apiController.getNotifications);

// Budgets
router.get('/budgets', apiController.getBudgets);
router.post('/budgets', apiController.addBudget);
router.put('/budgets/:id', apiController.updateBudget);
router.delete('/budgets/:id', apiController.deleteBudget);

module.exports = router;
