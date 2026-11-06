// Error "conocido" de la aplicación: lleva el código HTTP y un código propio legible.
// Ejemplo: throw new AppError(401, 'Token requerido', 'NO_TOKEN');
export class AppError extends Error {
  constructor(status, message, code = 'ERROR', details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}
