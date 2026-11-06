// Convierte CUALQUIER error en una respuesta con el mismo formato:
//   { ok: false, error: { code, message, details } }
import { AppError } from '../utils/AppError.js';

const enviar = (res, status, code, message, details) =>
  res.status(status).json({ ok: false, error: { code, message, details } });

// SQLSTATE propios que lanzan los procedimientos con SIGNAL (ver database/logica.sql)
const SQLSTATE = {
  45000: [422, 'BUSINESS_RULE'],
  45404: [404, 'NOT_FOUND'],
  45409: [409, 'DUPLICATE'],
};

// Errores propios de MySQL
const MYSQL = {
  ER_DUP_ENTRY: [409, 'DUPLICATE', 'Ya existe un registro con ese valor'],
  ER_NO_REFERENCED_ROW_2: [400, 'INVALID_REFERENCE', 'Hace referencia a un registro que no existe'],
  ER_ROW_IS_REFERENCED_2: [409, 'IN_USE', 'No se puede eliminar: tiene registros relacionados'],
  ER_CONSTRAINT_FAILED: [422, 'BUSINESS_RULE', 'Un valor no cumple las reglas de la base de datos'],
  ER_DATA_TOO_LONG: [400, 'VALIDATION_ERROR', 'Un texto es demasiado largo'],
};

// Sin conexión a la base de datos
const SIN_BASE = ['ECONNREFUSED', 'PROTOCOL_CONNECTION_LOST', 'ETIMEDOUT', 'ER_ACCESS_DENIED_ERROR'];

// Ruta que no existe
export function notFound(req, res) {
  enviar(res, 404, 'NOT_FOUND', `Ruta no encontrada: ${req.method} ${req.originalUrl}`);
}

// Express reconoce un manejador de errores por sus 4 parámetros: no quites "next"
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  if (err instanceof AppError) return enviar(res, err.status, err.code, err.message, err.details);

  // SIGNAL de un procedimiento o trigger: el mensaje ya viene en español desde MySQL
  if (SQLSTATE[err.sqlState]) {
    const [status, code] = SQLSTATE[err.sqlState];
    return enviar(res, status, code, err.sqlMessage);
  }
  if (MYSQL[err.code]) return enviar(res, ...MYSQL[err.code]);
  if (err.errno === 4025 || err.errno === 3819) return enviar(res, ...MYSQL.ER_CONSTRAINT_FAILED); // CHECK (MariaDB / MySQL)
  if (SIN_BASE.includes(err.code)) {
    console.error('Base de datos no disponible:', err.code);
    return enviar(res, 503, 'DB_UNAVAILABLE', 'La base de datos no está disponible. Intenta en un momento.');
  }
  if (err.type === 'entity.parse.failed') return enviar(res, 400, 'INVALID_JSON', 'El cuerpo no es un JSON válido');
  if (err.type === 'entity.too.large') return enviar(res, 413, 'PAYLOAD_TOO_LARGE', 'El cuerpo de la petición es demasiado grande');

  console.error(err); // el detalle técnico queda en la consola del servidor, nunca en la respuesta
  enviar(res, 500, 'INTERNAL_ERROR', 'Error interno del servidor');
}
