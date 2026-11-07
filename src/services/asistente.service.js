import { llamarUno } from '../utils/sp.js';
import { listarPreguntas } from './preguntas.service.js';

const SUGERENCIAS = 3;

// 1) Busca la respuesta preparada más parecida (FULLTEXT en MySQL).
// 2) Si no hay ninguna, sugiere preguntas que sí sabe responder.
// No guarda lo que pregunta el turista y no llama a servicios externos: responde al instante.
export async function preguntar(texto) {
  const encontrada = await llamarUno('sp_buscar_pregunta_frecuente', [texto]);
  if (encontrada) {
    return {
      encontrada: true,
      pregunta: encontrada.pregunta,
      respuesta: encontrada.respuesta,
      atractivo: encontrada.atractivo_id ? { id: encontrada.atractivo_id, nombre: encontrada.atractivo } : null,
    };
  }
  const todas = await listarPreguntas();
  return {
    encontrada: false,
    respuesta: 'Aún no tengo una respuesta para eso. Prueba con una de estas preguntas:',
    sugerencias: todas.slice(0, SUGERENCIAS).map((p) => p.pregunta),
  };
}
