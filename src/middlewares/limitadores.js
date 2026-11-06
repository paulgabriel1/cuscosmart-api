// Límites de peticiones (rate limit): frenan ataques de fuerza bruta y abusos.
// Se guardan en memoria: al reiniciar la API se vuelven a cero.
import rateLimit, { ipKeyGenerator } from 'express-rate-limit';

const respuesta = (message) => ({ ok: false, error: { code: 'TOO_MANY_REQUESTS', message } });

// Toda la API: 300 peticiones por minuto por IP (frena a quien intente saturar el servidor)
export const limiteGeneral = rateLimit({
  windowMs: 60 * 1000,
  limit: 300,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: respuesta('Demasiadas peticiones. Espera un minuto.'),
});

// Login y registro: 10 intentos FALLIDOS cada 15 minutos por IP y correo.
// - Los intentos correctos no cuentan (skipSuccessfulRequests).
// - Se cuenta por IP + correo: si alguien ataca una cuenta, no bloquea a las demás personas
//   que comparten la misma red (por ejemplo, el wifi del aula).
export const limiteAuth = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  skipSuccessfulRequests: true,
  keyGenerator: (req) => `${ipKeyGenerator(req.ip)}|${String(req.body?.correo ?? '').trim().toLowerCase()}`,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: respuesta('Demasiados intentos fallidos con este correo. Espera 15 minutos.'),
});

// Asistente: 20 preguntas por minuto por IP (no sobrecargar el servidor)
export const limiteAsistente = rateLimit({
  windowMs: 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: respuesta('Hiciste muchas preguntas seguidas. Espera un minuto.'),
});
