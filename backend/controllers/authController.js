const pool = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Secret for JWT (Usually kept in .env)
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_key_123';

const authController = {
  // Register a new user
  register: async (req, res) => {
    try {
      const { full_name, email, password } = req.body;

      // Input validation
      if (!full_name || !email || !password) {
        return res.status(400).json({ error: 'Please provide full_name, email, and password.' });
      }

      // Check if user exists
      const userExistsCheck = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
      if (userExistsCheck.rows.length > 0) {
        return res.status(400).json({ error: 'User with this email already exists.' });
      }

      // Hash password
      const saltRounds = 10;
      const password_hash = await bcrypt.hash(password, saltRounds);

      // Insert user
      const insertQuery = `
        INSERT INTO users (full_name, email, password_hash)
        VALUES ($1, $2, $3)
        RETURNING id, full_name, email, created_at;
      `;
      const result = await pool.query(insertQuery, [full_name, email, password_hash]);

      return res.status(201).json({
        message: 'User registered successfully',
        user: result.rows[0],
      });
    } catch (error) {
      console.error('Registration Error:', error);
      return res.status(500).json({ error: 'Internal server error during registration.' });
    }
  },

  // Login a user
  login: async (req, res) => {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ error: 'Please provide email and password.' });
      }

      // Fetch user from DB
      const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      if (result.rows.length === 0) {
        return res.status(401).json({ error: 'Invalid credentials.' });
      }

      const user = result.rows[0];

      // Compare password
      const isMatch = await bcrypt.compare(password, user.password_hash);
      if (!isMatch) {
        return res.status(401).json({ error: 'Invalid credentials.' });
      }

      // Check for 2FA flag
      if (user.is_2fa_active) {
        return res.status(200).json({
          message: '2FA required',
          requires2FA: true,
          userId: user.id
        });
      }

      // Generate token
      const token = jwt.sign(
        { id: user.id, email: user.email },
        JWT_SECRET,
        { expiresIn: '7d' } // Token expires in 7 days
      );

      return res.status(200).json({
        message: 'Login successful',
        token,
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email
        }
      });
    } catch (error) {
      console.error('Login Error:', error);
      return res.status(500).json({ error: 'Internal server error during login.' });
    }
  },

  // Get user profile (Protected Endpoint)
  getProfile: async (req, res) => {
    try {
      // req.user is supplied by authMiddleware
      const userId = req.user.id;

      const result = await pool.query(
        'SELECT id, full_name, email, is_2fa_active, created_at, updated_at FROM users WHERE id = $1',
        [userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found.' });
      }

      return res.status(200).json({
        user: result.rows[0],
      });
    } catch (error) {
      console.error('Profile Fetch Error:', error);
      return res.status(500).json({ error: 'Internal server error while fetching profile.' });
    }
  },

  // Update user profile
  updateProfile: async (req, res) => {
    try {
      const userId = req.user.id;
      const { full_name, email } = req.body;
      
      const result = await pool.query(
        'UPDATE users SET full_name = COALESCE($1, full_name), email = COALESCE($2, email), updated_at = CURRENT_TIMESTAMP WHERE id = $3 RETURNING id, full_name, email',
        [full_name, email, userId]
      );
      
      return res.status(200).json({ message: 'Profile updated', user: result.rows[0] });
    } catch (error) {
      console.error('Update Profile Error:', error);
      return res.status(500).json({ error: 'Failed to update profile.' });
    }
  },

  // Update security
  updateSecurity: async (req, res) => {
    try {
      const userId = req.user.id;
      const { password, is_2fa_active } = req.body;
      let updates = [];
      let values = [];
      let counter = 1;

      if (password) {
        const saltRounds = 10;
        const password_hash = await bcrypt.hash(password, saltRounds);
        updates.push(`password_hash = $${counter}`);
        values.push(password_hash);
        counter++;
      }
      if (is_2fa_active !== undefined) {
        updates.push(`is_2fa_active = $${counter}`);
        values.push(is_2fa_active);
        counter++;
      }

      if (updates.length > 0) {
        values.push(userId);
        await pool.query(
          `UPDATE users SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = $${counter}`,
          values
        );
      }
      return res.status(200).json({ message: 'Security updated successfully' });
    } catch (error) {
      console.error('Update Security Error:', error);
      return res.status(500).json({ error: 'Failed to update security parameters.' });
    }
  }
};

module.exports = authController;
