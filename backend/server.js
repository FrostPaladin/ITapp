const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Database = require('better-sqlite3');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Инициализация SQLite (файл database.db создастся автоматически)
const db = new Database('database.db');

// Создание всех таблиц
db.exec(`
  -- Таблица пользователей
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nickname TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  -- Таблица заявок
  CREATE TABLE IF NOT EXISTS tickets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'open',
    priority TEXT DEFAULT 'medium',
    category TEXT DEFAULT 'Другое',
    user_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );

  -- Таблица комментариев
  CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id INTEGER,
    user_id INTEGER,
    text TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );

  -- Создаем индексы для ускорения запросов
  CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON tickets(user_id);
  CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
  CREATE INDEX IF NOT EXISTS idx_comments_ticket_id ON comments(ticket_id);
`);

db.exec(`
  ALTER TABLE users ADD COLUMN avatar TEXT;
`.replace(/\n/g, ' '), (err) => {
  if (err && !err.message.includes('duplicate column name')) {
    console.log('Avatar column already exists or error:', err);
  }
});

console.log('✅ База данных инициализирована');

// Middleware
app.use(cors());
app.use(express.json());

// Middleware для проверки JWT токена
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Требуется авторизация' });
  }
  
  try {
    const user = jwt.verify(token, process.env.JWT_SECRET || 'super_secret_key_2024');
    req.userId = user.userId;
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Недействительный токен' });
  }
};

// ============= AUTH ROUTES =============

// Регистрация
app.post('/api/auth/register', async (req, res) => {
  const { nickname, email, password } = req.body;
  
  if (!nickname || !email || !password) {
    return res.status(400).json({ error: 'Все поля обязательны' });
  }
  
  try {
    // Хешируем пароль
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Сохраняем пользователя
    const stmt = db.prepare('INSERT INTO users (nickname, email, password_hash) VALUES (?, ?, ?)');
    const result = stmt.run(nickname, email, hashedPassword);
    
    // Создаем JWT токен
    const token = jwt.sign(
      { userId: result.lastInsertRowid, email },
      process.env.JWT_SECRET || 'super_secret_key_2024',
      { expiresIn: '7d' }
    );
    
    res.json({
      token,
      user: {
        id: result.lastInsertRowid,
        nickname: nickname,
        email: email
      }
    });
  } catch (err) {
    if (err.message.includes('UNIQUE constraint failed')) {
      res.status(400).json({ error: 'Email уже зарегистрирован' });
    } else {
      console.error(err);
      res.status(500).json({ error: 'Ошибка при регистрации' });
    }
  }
});

// Вход
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: 'Email и пароль обязательны' });
  }
  
  try {
    const stmt = db.prepare('SELECT id, nickname, email, password_hash FROM users WHERE email = ?');
    const user = stmt.get(email);
    
    if (!user) {
      return res.status(401).json({ error: 'Неверный email или пароль' });
    }
    
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Неверный email или пароль' });
    }
    
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET || 'super_secret_key_2024',
      { expiresIn: '7d' }
    );
    
    res.json({
      token,
      user: {
        id: user.id,
        nickname: user.nickname,
        email: user.email
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при входе' });
  }
});

// ============= TICKETS ROUTES =============

// Получить все заявки пользователя
app.get('/api/tickets', authenticateToken, (req, res) => {
  try {
    const stmt = db.prepare(`
      SELECT * FROM tickets 
      WHERE user_id = ? 
      ORDER BY created_at DESC
    `);
    const tickets = stmt.all(req.userId);
    res.json(tickets);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при получении заявок' });
  }
});

// Получить одну заявку с комментариями
app.get('/api/tickets/:id', authenticateToken, (req, res) => {
  try {
    // Получаем заявку
    const ticketStmt = db.prepare('SELECT * FROM tickets WHERE id = ? AND user_id = ?');
    const ticket = ticketStmt.get(req.params.id, req.userId);
    
    if (!ticket) {
      return res.status(404).json({ error: 'Заявка не найдена' });
    }
    
    // Получаем комментарии
    const commentsStmt = db.prepare(`
      SELECT c.*, u.nickname 
      FROM comments c 
      JOIN users u ON c.user_id = u.id 
      WHERE c.ticket_id = ? 
      ORDER BY c.created_at ASC
    `);
    const comments = commentsStmt.all(req.params.id);
    
    res.json({ ...ticket, comments });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при получении заявки' });
  }
});

// Создать заявку
app.post('/api/tickets', authenticateToken, (req, res) => {
  const { title, description, priority, category } = req.body;
  
  if (!title) {
    return res.status(400).json({ error: 'Название заявки обязательно' });
  }
  
  try {
    const stmt = db.prepare(`
      INSERT INTO tickets (title, description, priority, category, user_id) 
      VALUES (?, ?, ?, ?, ?)
    `);
    const result = stmt.run(
      title, 
      description || '', 
      priority || 'medium', 
      category || 'Другое', 
      req.userId
    );
    
    const getStmt = db.prepare('SELECT * FROM tickets WHERE id = ?');
    const ticket = getStmt.get(result.lastInsertRowid);
    
    res.json(ticket);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при создании заявки' });
  }
});

// Обновить заявку
app.put('/api/tickets/:id', authenticateToken, (req, res) => {
  const { title, description, status, priority, category } = req.body;
  
  try {
    const stmt = db.prepare(`
      UPDATE tickets 
      SET title = COALESCE(?, title),
          description = COALESCE(?, description),
          status = COALESCE(?, status),
          priority = COALESCE(?, priority),
          category = COALESCE(?, category),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = ? AND user_id = ?
      RETURNING *
    `);
    
    const ticket = stmt.get(
      title, description, status, priority, category, 
      req.params.id, req.userId
    );
    
    if (!ticket) {
      return res.status(404).json({ error: 'Заявка не найдена' });
    }
    
    res.json(ticket);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при обновлении заявки' });
  }
});

// Удалить заявку
app.delete('/api/tickets/:id', authenticateToken, (req, res) => {
  try {
    const stmt = db.prepare('DELETE FROM tickets WHERE id = ? AND user_id = ?');
    const result = stmt.run(req.params.id, req.userId);
    
    if (result.changes === 0) {
      return res.status(404).json({ error: 'Заявка не найдена' });
    }
    
    res.json({ message: 'Заявка удалена' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при удалении заявки' });
  }
});

// ============= COMMENTS ROUTES =============

// Добавить комментарий к заявке
app.post('/api/tickets/:id/comments', authenticateToken, (req, res) => {
  const { text } = req.body;
  
  if (!text) {
    return res.status(400).json({ error: 'Текст комментария обязателен' });
  }
  
  try {
    // Проверяем, существует ли заявка и принадлежит ли пользователю
    const checkStmt = db.prepare('SELECT id FROM tickets WHERE id = ? AND user_id = ?');
    const ticket = checkStmt.get(req.params.id, req.userId);
    
    if (!ticket) {
      return res.status(404).json({ error: 'Заявка не найдена' });
    }
    
    // Добавляем комментарий
    const insertStmt = db.prepare(`
      INSERT INTO comments (ticket_id, user_id, text) 
      VALUES (?, ?, ?)
    `);
    const result = insertStmt.run(req.params.id, req.userId, text);
    
    // Получаем добавленный комментарий с ником пользователя
    const getStmt = db.prepare(`
      SELECT c.*, u.nickname 
      FROM comments c 
      JOIN users u ON c.user_id = u.id 
      WHERE c.id = ?
    `);
    const comment = getStmt.get(result.lastInsertRowid);
    
    res.json(comment);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при добавлении комментария' });
  }
});

// ============= CATEGORIES ROUTES =============

// Получить список категорий
app.get('/api/categories', (req, res) => {
  res.json([
    { id: 1, name: 'Оборудование', icon: 'computer' },
    { id: 2, name: 'Программное обеспечение', icon: 'code' },
    { id: 3, name: 'Доступы', icon: 'vpn_key' },
    { id: 4, name: 'Сеть', icon: 'wifi' },
    { id: 5, name: 'Другое', icon: 'help' }
  ]);
});

// ============= HEALTH CHECK =============
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    database: 'SQLite'
  });
});
// ============= PROFILE ROUTES =============

// Обновить профиль пользователя
app.put('/api/profile', authenticateToken, async (req, res) => {
  const { nickname } = req.body;
  
  try {
    const stmt = db.prepare(`
      UPDATE users 
      SET nickname = COALESCE(?, nickname)
      WHERE id = ?
      RETURNING id, nickname, email
    `);
    
    const user = stmt.get(nickname, req.userId);
    
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при обновлении профиля' });
  }
});

// Сменить пароль
app.put('/api/profile/password', authenticateToken, async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  
  if (!currentPassword || !newPassword) {
    return res.status(400).json({ error: 'Все поля обязательны' });
  }
  
  if (newPassword.length < 4) {
    return res.status(400).json({ error: 'Пароль должен быть не менее 4 символов' });
  }
  
  try {
    // Получаем текущего пользователя
    const userStmt = db.prepare('SELECT password_hash FROM users WHERE id = ?');
    const user = userStmt.get(req.userId);
    
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    // Проверяем текущий пароль
    const validPassword = await bcrypt.compare(currentPassword, user.password_hash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Неверный текущий пароль' });
    }
    
    // Хешируем новый пароль
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Обновляем пароль
    const updateStmt = db.prepare('UPDATE users SET password_hash = ? WHERE id = ?');
    updateStmt.run(hashedPassword, req.userId);
    
    res.json({ message: 'Пароль успешно изменен' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при смене пароля' });
  }
});

// Загрузить аватарку (сохраняем base64)
app.post('/api/profile/avatar', authenticateToken, async (req, res) => {
  const { avatar } = req.body;
  
  try {
    const stmt = db.prepare(`
      UPDATE users 
      SET avatar = ?
      WHERE id = ?
      RETURNING id, nickname, email, avatar
    `);
    
    const user = stmt.get(avatar, req.userId);
    
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    res.json({ avatar: user.avatar });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при загрузке аватарки' });
  }
});

// Получить профиль
app.get('/api/profile', authenticateToken, (req, res) => {
  try {
    const stmt = db.prepare('SELECT id, nickname, email, avatar, created_at FROM users WHERE id = ?');
    const user = stmt.get(req.userId);
    
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ошибка при получении профиля' });
  }
});

// ============= ЗАПУСК СЕРВЕРА =============
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Сервер успешно запущен!`);
  console.log(`📍 Адрес: http://localhost:${PORT}`);
  console.log(`📁 База данных: backend/database.db`);
  console.log(`\n📝 Доступные маршруты:`);
  console.log(`   POST /api/auth/register - регистрация`);
  console.log(`   POST /api/auth/login - вход`);
  console.log(`   GET  /api/tickets - все заявки`);
  console.log(`   POST /api/tickets - создать заявку`);
  console.log(`   PUT  /api/tickets/:id - обновить заявку`);
  console.log(`   DELETE /api/tickets/:id - удалить заявку`);
  console.log(`   POST /api/tickets/:id/comments - добавить комментарий`);
  console.log(`   GET  /api/categories - категории\n`);
});