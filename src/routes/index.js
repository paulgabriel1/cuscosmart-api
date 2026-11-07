// Mapa de todas las rutas de la API (prefijo /api/v1)
import { Router } from 'express';
import { pool } from '../config/db.js';
import auth from './auth.routes.js';
import categorias from './categorias.routes.js';
import zonas from './zonas.routes.js';
import atractivos from './atractivos.routes.js';
import resenas, { resenasDeAtractivo } from './resenas.routes.js';
import favoritos from './favoritos.routes.js';
import itinerarios from './itinerarios.routes.js';
import asistente from './asistente.routes.js';
import preguntas from './preguntas.routes.js';
import usuarios from './usuarios.routes.js';

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

router.use('/auth', auth);                                 // público
router.use('/categorias', categorias);                     // leer público · escribir ADMIN
router.use('/zonas', zonas);                               // leer público · escribir ADMIN
router.use('/atractivos/:id/resenas', resenasDeAtractivo); // público
router.use('/atractivos', atractivos);                     // leer público · escribir ADMIN
router.use('/favoritos', favoritos);                       // con token (solo lo propio)
router.use('/itinerarios', itinerarios);                   // con token (solo lo propio)
router.use('/asistente', asistente);                       // público, 20 por minuto
router.use('/preguntas-frecuentes', preguntas);            // leer público · escribir ADMIN
router.use('/resenas', resenas);                           // moderación ADMIN
router.use('/usuarios', usuarios);                         // ADMIN

export default router;
