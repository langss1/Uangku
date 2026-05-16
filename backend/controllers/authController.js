const pool = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { authenticator } = require('otplib');
const nodemailer = require('nodemailer');

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
      // Standardize on is_2fa_active for TOTP/General 2FA status
      const is2FAActive = user.is_2fa_active === true || user.two_factor_enabled === true;
      
      if (is2FAActive) {
        const type = user.two_factor_type && user.two_factor_type !== 'NONE' ? user.two_factor_type : 'TOTP';

        if (type === 'EMAIL' || type === 'BOTH') {
            await authController.sendEmailOTP(user.email, user.id);
        }

        const tempToken = jwt.sign(
            { id: user.id, email: user.email, isTemp: true },
            JWT_SECRET,
            { expiresIn: '5m' }
        );

        return res.status(200).json({
          message: '2FA required',
          requires2FA: true,
          twoFactorType: type,
          tempToken: tempToken,
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
        'SELECT id, full_name, email, is_2fa_active, two_factor_enabled, two_factor_type, created_at, updated_at FROM users WHERE id = $1',
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
  },

  // --- NEW 2FA LOGIC ---

  generateTOTP: async (req, res) => {
    try {
      const email = req.user.email;
      const secret = authenticator.generateSecret();
      
      // Membuat URL buat di-render jadi QR Code di Flutter
      const otpauthUrl = authenticator.keyuri(email, 'UANGKU AI', secret);
      
      // Simpan ke kolom totp_secret sesuai skema database kamu
      await pool.query('UPDATE users SET totp_secret = $1 WHERE id = $2', [secret, req.user.id]);
      
      res.json({ secret, qrCodeUrl: otpauthUrl });
    } catch (error) {
      console.error('generateTOTP error:', error);
      res.status(500).json({ error: 'Failed to generate TOTP' });
    }
  },

  verifyAndEnableTOTP: async (req, res) => {
    try {
      const { token } = req.body;
      const userResult = await pool.query('SELECT totp_secret, two_factor_secret FROM users WHERE id = $1', [req.user.id]);
      
      if (userResult.rows.length === 0) {
        return res.status(400).json({ success: false, message: "User not found" });
      }

      const secret = userResult.rows[0].totp_secret || userResult.rows[0].two_factor_secret;
      
      if (!secret) {
        return res.status(400).json({ success: false, message: "No TOTP secret found. Please generate QR code first." });
      }

      const isValid = authenticator.check(token, secret);
      
      if (isValid) {
          // Sync both columns to be safe, set active status
          await pool.query(
            "UPDATE users SET is_2fa_active = true, two_factor_enabled = true, two_factor_type = 'TOTP' WHERE id = $1", 
            [req.user.id]
          );
          return res.json({ success: true, message: "2FA Google Authenticator Aktif!" });
      }
      
      res.status(400).json({ success: false, message: "Token tidak valid" });
    } catch (error) {
      console.error('verifyAndEnableTOTP error:', error);
      res.status(500).json({ error: 'Failed to verify TOTP' });
    }
  },

  sendEmailOTP: async (userEmail, userId) => {
    const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT || '465', 10),
        secure: true,
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    });

    const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6 digit angka
    const expires = new Date(Date.now() + 5 * 60 * 1000); // Valid 5 menit

    await pool.query(
        'UPDATE users SET email_otp_secret = $1, email_otp_expires = $2 WHERE id = $3',
        [otp, expires, userId]
    );

    try {
        await transporter.sendMail({
            from: '"UANGKU AI" <no-reply@uangku.ai>',
            to: userEmail,
            subject: 'Kode Keamanan 2FA UANGKU AI',
            text: `Kode OTP kamu adalah: ${otp}. Kode ini berlaku selama 5 menit.`
        });
    } catch (err) {
        console.error('Email send error:', err);
    }
  },

  update2FAType: async (req, res) => {
    try {
      const { type, enabled } = req.body;
      const validTypes = ['NONE', 'TOTP', 'EMAIL', 'BOTH'];
      if (!validTypes.includes(type)) {
        return res.status(400).json({ error: 'Invalid 2FA type' });
      }

      // If type is NONE, we disable everything
      const finalEnabled = type === 'NONE' ? false : enabled;
      
      await pool.query(
        'UPDATE users SET two_factor_enabled = $1, is_2fa_active = $1, two_factor_type = $2 WHERE id = $3', 
        [finalEnabled, type, req.user.id]
      );
      res.json({ success: true, message: '2FA settings updated' });
    } catch (error) {
      console.error('update2FAType error:', error);
      res.status(500).json({ error: 'Failed to update 2FA settings' });
    }
  },

  verify2FALogin: async (req, res) => {
    try {
      const { tempToken, token } = req.body;
      
      let decoded;
      try {
        decoded = jwt.verify(tempToken, JWT_SECRET);
      } catch (err) {
        return res.status(401).json({ error: 'Temporary token expired or invalid' });
      }

      if (!decoded.isTemp) {
        return res.status(400).json({ error: 'Invalid token type' });
      }

      const userId = decoded.id;
      const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
      if (userResult.rows.length === 0) return res.status(404).json({ error: 'User not found' });

      const user = userResult.rows[0];
      const type = user.two_factor_type || 'TOTP';

      let isValid = false;

      // Check TOTP
      if (type === 'TOTP' || type === 'BOTH' || user.is_2fa_active) {
        const secret = user.totp_secret || user.two_factor_secret;
        if (secret) {
          isValid = authenticator.check(token, secret);
        }
      }

      // Check Email OTP if TOTP failed or if it's the required method
      if (!isValid && (type === 'EMAIL' || type === 'BOTH')) {
        if (user.email_otp_secret && user.email_otp_secret === token) {
          const now = new Date();
          const expires = new Date(user.email_otp_expires);
          if (now <= expires) {
            isValid = true;
            await pool.query('UPDATE users SET email_otp_secret = NULL WHERE id = $1', [userId]);
          }
        }
      }

      if (isValid) {
        const finalToken = jwt.sign(
          { id: user.id, email: user.email },
          JWT_SECRET,
          { expiresIn: '7d' }
        );

        return res.status(200).json({
          message: 'Login successful',
          token: finalToken,
          user: {
            id: user.id,
            full_name: user.full_name,
            email: user.email
          }
        });
      } else {
        return res.status(401).json({ error: 'Invalid 2FA token' });
      }

    } catch (error) {
      console.error('verify2FALogin error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
};

module.exports = authController;
