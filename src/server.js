import { env } from './config/env.js';
import { pool } from './config/db.js';
import app from './app.js';

// Antes de abrir el puerto, comprobamos que MySQL responde
try {
  const conn = await pool.getConnection();
  await conn.ping();
  conn.release();
  console.log('✅ Conectado a MySQL');
} catch (e) {
  console.error('❌ No se pudo conectar a MySQL:', e.message);
  console.error('   ¿Encendiste MySQL en XAMPP? ¿Están bien DB_USER y DB_PASSWORD en .env?');
  process.exit(1);
}

app.listen(env.port, () => console.log(`🚀 API en http://localhost:${env.port}/api/v1`));
