import { Router } from 'express';
import { validate } from '../middlewares/validate.js';
import { authenticate } from '../middlewares/auth.js';
import { limiteAuth } from '../middlewares/limitadores.js';
import { registroSchema, loginSchema } from '../schemas/auth.schema.js';
import * as ctrl from '../controllers/auth.controller.js';

const router = Router();

router.post('/registro', limiteAuth, validate(registroSchema), ctrl.registro);
router.post('/login', limiteAuth, validate(loginSchema), ctrl.login);
router.get('/me', authenticate, ctrl.me);

export default router;
