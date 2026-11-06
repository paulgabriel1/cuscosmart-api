// Valida los datos de entrada con un esquema zod ANTES de llegar al controlador.
// Uso: validate(esquema)            → valida req.body
//      validate(esquema, 'query')   → valida ?filtros=de&la=url
//      validate(esquema, 'params')  → valida /recurso/:id
// Los datos limpios quedan en req.body (para el cuerpo) o en req.validado.query / req.validado.params.
import { AppError } from '../utils/AppError.js';

export const validate = (esquema, origen = 'body') => (req, res, next) => {
  const resultado = esquema.safeParse(req[origen] ?? {});
  if (!resultado.success) {
    const details = resultado.error.issues.map((i) => ({ campo: i.path.join('.') || origen, mensaje: i.message }));
    throw new AppError(400, 'Datos inválidos', 'VALIDATION_ERROR', details);
  }
  if (origen === 'body') req.body = resultado.data;
  // En Express 5, req.query y req.params son de solo lectura: guardamos la versión limpia aparte
  req.validado = { ...req.validado, [origen]: resultado.data };
  next();
};
