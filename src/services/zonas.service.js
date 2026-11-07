// Cada función solo llama a un procedimiento almacenado (la lógica está en MySQL).
import { llamar, llamarUno } from '../utils/sp.js';

export const listarZonas = async () => (await llamar('sp_listar_zonas'))[0];
export const verZona = (id) => llamarUno('sp_ver_zona', [id]);
export const crearZona = ({ nombre, ciudad }) => llamarUno('sp_crear_zona', [nombre, ciudad]);
export const actualizarZona = (id, { nombre, ciudad }) => llamarUno('sp_actualizar_zona', [id, nombre, ciudad]);
export const eliminarZona = (id) => llamar('sp_eliminar_zona', [id]);
