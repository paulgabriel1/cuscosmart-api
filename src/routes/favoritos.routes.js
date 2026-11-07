// Rutas privadas del turista: todas exigen token (router.use(authenticate)).
// No hace falta comprobar "es el dueño" aquí: los procedimientos lo validan con el id del token.
import { Router } from 'express';
import { authenticate } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { idParam } from '../schemas/comunes.js';
import { favoritoSchema } from '../schemas/favoritos.schema.js';
import * as c from '../controllers/favoritos.controller.js';

const router = Router();
const conId = validate(idParam, 'params');

router.use(authenticate);
router.get('/', c.listarFavoritos);
router.post('/', validate(favoritoSchema), c.agregarFavorito);
router.delete('/:id', conId, c.quitarFavorito);

export default router;
