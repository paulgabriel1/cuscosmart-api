// Recibe archivos (multipart/form-data) con multer. Quedan en memoria (req.files / req.file)
// y luego utils/imagenes.js revisa que sean imágenes de verdad antes de guardarlas.
import multer from 'multer';
import { AppError } from '../utils/AppError.js';
import { MAX_BYTES } from '../utils/imagenes.js';

const MAX_ARCHIVOS = 5;

const subir = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_BYTES, files: MAX_ARCHIVOS, fields: 5 },
  fileFilter: (req, file, cb) => cb(null, /^image\//.test(file.mimetype)), // los que no son imagen se ignoran
});

// Traduce los errores de multer a nuestro formato { ok:false, error }
const conErrores = (mw) => (req, res, next) => mw(req, res, (err) => {
  if (!err) return next();
  const mensajes = {
    LIMIT_FILE_SIZE: 'Cada imagen puede pesar como máximo 5 MB',
    LIMIT_FILE_COUNT: `Puedes subir como máximo ${MAX_ARCHIVOS} imágenes a la vez`,
    LIMIT_UNEXPECTED_FILE: 'Campo de archivo inesperado',
  };
  next(new AppError(400, mensajes[err.code] ?? 'No se pudo leer el archivo', 'UPLOAD_ERROR'));
});

export const subirFotos = conErrores(subir.array('fotos', MAX_ARCHIVOS));
export const subirFotoPerfil = conErrores(subir.single('foto'));
