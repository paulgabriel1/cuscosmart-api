// Cada función solo llama a un procedimiento almacenado (la lógica está en MySQL).
import { llamar, llamarUno } from '../utils/sp.js';

export const listarCategorias = async () => (await llamar('sp_listar_categorias'))[0];
export const verCategoria = (id) => llamarUno('sp_ver_categoria', [id]);
export const crearCategoria = ({ nombre, descripcion }) => llamarUno('sp_crear_categoria', [nombre, descripcion]);
export const actualizarCategoria = (id, { nombre, descripcion }) =>
  llamarUno('sp_actualizar_categoria', [id, nombre, descripcion]);
export const eliminarCategoria = (id) => llamar('sp_eliminar_categoria', [id]);
