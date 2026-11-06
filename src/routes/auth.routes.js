import { Router } from 'express';
import { validate } from '../middlewares/validate.js';
import { authenticate } from '../middlewares/auth.js';
import { limiteAuth } from '../middlewares/limitadores.js';
import { registroSchema, loginSchema, googleSchema, perfilSchema } from '../schemas/auth.schema.js';
import * as ctrl from '../controllers/auth.controller.js';

const router = Router();

router.get('/config', ctrl.config); // el front pregunta si Google está activo
router.post('/registro', limiteAuth, validate(registroSchema), ctrl.registro);
router.post('/login', limiteAuth, validate(loginSchema), ctrl.login);
router.post('/google', limiteAuth, validate(googleSchema), ctrl.google);
router.get('/me', authenticate, ctrl.me);
router.put('/me', authenticate, validate(perfilSchema), ctrl.actualizarMe);

export default router;
