// Límites de peticiones (rate limit): frenan ataques de fuerza bruta y abusos.
// Se guardan en memoria: al reiniciar la API se vuelven a cero.
import rateLimit from 'express-rate-limit';

const respuesta = (message) => ({ ok: false, error: { code: 'TOO_MANY_REQUESTS', message } });

// Login y registro: 20 intentos cada 15 minutos por IP
export const limiteAuth = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: respuesta('Demasiados intentos. Espera 15 minutos.'),
});

// Asistente: 20 preguntas por minuto por IP (no sobrecargar el servidor)
export const limiteAsistente = rateLimit({
  windowMs: 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: respuesta('Hiciste muchas preguntas seguidas. Espera un minuto.'),
});
