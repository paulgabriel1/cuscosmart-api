// Público, con límite de 20 peticiones por minuto
import { Router } from 'express';
import { validate } from '../middlewares/validate.js';
import { limiteAsistente } from '../middlewares/limitadores.js';
import { preguntarSchema } from '../schemas/asistente.schema.js';
import * as c from '../controllers/asistente.controller.js';

const router = Router();

router.post('/preguntar', limiteAsistente, validate(preguntarSchema), c.preguntar);

export default router;
