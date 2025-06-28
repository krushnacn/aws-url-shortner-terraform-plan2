const express = require('express');
const mysql = require('mysql2/promise');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(rateLimit({ windowMs: 60000, max: 60 }));

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
});

function authenticate(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token missing' });

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ error: 'Unauthorized' });
  }
}

app.post('/login', (req, res) => {
  if (
    req.body.user === process.env.API_USER &&
    req.body.pass === process.env.API_PASS
  ) {
    const token = jwt.sign({ user: req.body.user }, process.env.JWT_SECRET);
    res.json({ token });
  } else res.status(401).end();
});

app.post('/shorten', authenticate, async (req, res) => {
  const short = Math.random().toString(36).substring(2, 8);
  await pool.query('INSERT INTO urls (short, original) VALUES (?, ?)', [
    short,
    req.body.url
  ]);
  res.json({ short });
});

app.get('/:short', async (req, res) => {
  const [rows] = await pool.query('SELECT original FROM urls WHERE short = ?', [
    req.params.short
  ]);
  if (rows.length) return res.redirect(rows[0].original);
  res.status(404).end();
});

app.listen(3000, () => console.log('Server running on port 3000'));
