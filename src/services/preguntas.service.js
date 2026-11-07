// Preguntas frecuentes del asistente
import { llamar, llamarUno } from '../utils/sp.js';

export const listarPreguntas = async () => (await llamar('sp_listar_preguntas'))[0];
const datosPregunta = (d) => [d.pregunta, d.respuesta, d.palabras_clave, d.atractivo_id ?? null];
export const crearPregunta = (d) => llamarUno('sp_crear_pregunta', datosPregunta(d));
export const actualizarPregunta = (id, d) => llamarUno('sp_actualizar_pregunta', [id, ...datosPregunta(d)]);
export const eliminarPregunta = (id) => llamar('sp_eliminar_pregunta', [id]);
