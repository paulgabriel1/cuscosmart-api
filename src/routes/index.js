import { Router } from 'express';
import { pool } from '../config/db.js';

const router = Router();

// ¿Está viva la API y llega a la base de datos? (ping no ejecuta SQL)
router.get('/health', async (req, res) => {
  let db = 'up';
  try {
    const conn = await pool.getConnection();
    await conn.ping();
    conn.release();
  } catch {
    db = 'down';
  }
  res.status(db === 'up' ? 200 : 503).json({ ok: db === 'up', data: { status: 'up', db } });
});

export default router;
