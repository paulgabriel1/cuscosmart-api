// Mapa de todas las rutas de la API (prefijo /api/v1)
import { Router } from 'express';
import { pool } from '../config/db.js';
import authRoutes from './auth.routes.js';
import { categorias, zonas, atractivos } from './catalogo.routes.js';
import { favoritos, itinerarios } from './viaje.routes.js';
<<<<<<< Updated upstream
=======
import { asistente, preguntas, resenasDeAtractivo, resenas, usuarios } from './admin.routes.js';
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
router.use('/auth', authRoutes);
router.use('/categorias', categorias);
router.use('/zonas', zonas);
router.use('/atractivos', atractivos);
router.use('/favoritos', favoritos);
router.use('/itinerarios', itinerarios);
=======
router.use('/auth', authRoutes);                           // público
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
>>>>>>> Stashed changes

export default router;
