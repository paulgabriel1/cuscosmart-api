// Rutas privadas del turista: todas exigen token (router.use(authenticate)).
// No hace falta comprobar "es el dueño" aquí: los procedimientos lo validan con el id del token.
import { Router } from 'express';
import { authenticate } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { idParam } from '../schemas/comunes.js';
import { favoritoSchema, itinerarioSchema, paradaSchema, resenaSchema, paradaParams } from '../schemas/viaje.schema.js';
import * as c from '../controllers/viaje.controller.js';

const conId = validate(idParam, 'params');
const conParada = validate(paradaParams, 'params');

// ---------- /favoritos ----------
export const favoritos = Router();
favoritos.use(authenticate);
favoritos.get('/', c.listarFavoritos);
favoritos.post('/', validate(favoritoSchema), c.agregarFavorito);
favoritos.delete('/:id', conId, c.quitarFavorito);

// ---------- /itinerarios ----------
export const itinerarios = Router();
itinerarios.use(authenticate);
itinerarios.get('/', c.listarItinerarios);
itinerarios.get('/recorrido', c.miRecorrido); // antes de /:id
itinerarios.post('/', validate(itinerarioSchema), c.crearItinerario);
itinerarios.get('/:id', conId, c.verItinerario);
itinerarios.put('/:id', conId, validate(itinerarioSchema), c.actualizarItinerario);
itinerarios.delete('/:id', conId, c.eliminarItinerario);

itinerarios.post('/:id/paradas', conId, validate(paradaSchema), c.agregarParada);
itinerarios.delete('/:id/paradas/:paradaId', conParada, c.quitarParada);
itinerarios.patch('/:id/paradas/:paradaId/visitado', conParada, c.marcarVisitado);
itinerarios.delete('/:id/paradas/:paradaId/visitado', conParada, c.desmarcarVisitado);
itinerarios.post('/:id/ordenar-ia', conId, c.ordenarConIA);

itinerarios.post('/:id/resenas', conId, validate(resenaSchema), c.registrarResena);
