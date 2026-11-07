// Rutas privadas del turista: todas exigen token (router.use(authenticate)).
// No hace falta comprobar "es el dueño" aquí: los procedimientos lo validan con el id del token.
import { Router } from 'express';
import { authenticate } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { idParam } from '../schemas/comunes.js';
import { itinerarioSchema, paradaSchema, paradaParams } from '../schemas/itinerarios.schema.js';
import { favoritoSchema } from '../schemas/favoritos.schema.js';
import { resenaSchema } from '../schemas/resenas.schema.js';
import * as c from '../controllers/itinerarios.controller.js';
import { registrarResena } from '../controllers/resenas.controller.js';

const router = Router();
const conId = validate(idParam, 'params');
const conParada = validate(paradaParams, 'params');

router.use(authenticate);
router.get('/', c.listarItinerarios);
router.get('/recorrido', c.miRecorrido); // antes de /:id
router.post('/', validate(itinerarioSchema), c.crearItinerario);
router.post('/visitar', validate(favoritoSchema), c.visitarLugar); // { atractivo_id }
router.get('/:id', conId, c.verItinerario);
router.put('/:id', conId, validate(itinerarioSchema), c.actualizarItinerario);
router.delete('/:id', conId, c.eliminarItinerario);

router.post('/:id/paradas', conId, validate(paradaSchema), c.agregarParada);
router.post('/:id/favoritos', conId, c.agregarFavoritos);
router.delete('/:id/paradas/:paradaId', conParada, c.quitarParada);
router.patch('/:id/paradas/:paradaId/visitado', conParada, c.marcarVisitado);
router.delete('/:id/paradas/:paradaId/visitado', conParada, c.desmarcarVisitado);
router.post('/:id/ordenar-ia', conId, c.ordenarConIA);

router.post('/:id/resenas', conId, validate(resenaSchema), registrarResena);

export default router;
