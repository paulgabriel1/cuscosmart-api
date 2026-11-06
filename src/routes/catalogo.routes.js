// Rutas del catálogo. Leer es PÚBLICO (cualquier turista sin cuenta); escribir es solo ADMIN.
import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { idParam } from '../schemas/comunes.js';
import {
  categoriaSchema, zonaSchema, atractivoSchema, listarAtractivosQuery, cercanosQuery,
  horarioSchema, fotoSchema, horarioParams, fotoParams,
} from '../schemas/catalogo.schema.js';
import * as c from '../controllers/catalogo.controller.js';

const soloAdmin = [authenticate, authorize('ADMIN')];
const conId = validate(idParam, 'params');

// ---------- /categorias ----------
export const categorias = Router();
categorias.get('/', c.listarCategorias);
categorias.get('/:id', conId, c.verCategoria);
categorias.post('/', soloAdmin, validate(categoriaSchema), c.crearCategoria);
categorias.put('/:id', soloAdmin, conId, validate(categoriaSchema), c.actualizarCategoria);
categorias.delete('/:id', soloAdmin, conId, c.eliminarCategoria);

// ---------- /zonas ----------
export const zonas = Router();
zonas.get('/', c.listarZonas);
zonas.get('/:id', conId, c.verZona);
zonas.post('/', soloAdmin, validate(zonaSchema), c.crearZona);
zonas.put('/:id', soloAdmin, conId, validate(zonaSchema), c.actualizarZona);
zonas.delete('/:id', soloAdmin, conId, c.eliminarZona);

// ---------- /atractivos ----------
export const atractivos = Router();
atractivos.get('/', validate(listarAtractivosQuery, 'query'), c.listarAtractivos);
atractivos.get('/cercanos', validate(cercanosQuery, 'query'), c.cercanos); // antes de /:id
atractivos.get('/:id', conId, c.verAtractivo);
atractivos.post('/', soloAdmin, validate(atractivoSchema), c.crearAtractivo);
atractivos.put('/:id', soloAdmin, conId, validate(atractivoSchema), c.actualizarAtractivo);
atractivos.delete('/:id', soloAdmin, conId, c.eliminarAtractivo);

atractivos.get('/:id/horarios', conId, c.listarHorarios);
atractivos.post('/:id/horarios', soloAdmin, conId, validate(horarioSchema), c.agregarHorario);
atractivos.delete('/:id/horarios/:horarioId', soloAdmin, validate(horarioParams, 'params'), c.eliminarHorario);

atractivos.get('/:id/fotos', conId, c.listarFotos);
atractivos.post('/:id/fotos', soloAdmin, conId, validate(fotoSchema), c.agregarFoto);
atractivos.delete('/:id/fotos/:fotoId', soloAdmin, validate(fotoParams, 'params'), c.eliminarFoto);
