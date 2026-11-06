// Única puerta de la API hacia MySQL: ejecuta procedimientos almacenados.
// La API NO escribe SELECT/INSERT/UPDATE: toda la lógica de datos vive en database/logica.sql.
import { pool } from '../config/db.js';

const NOMBRE_VALIDO = /^sp_[a-z_]+$/;

/**
 * Ejecuta CALL sp_nombre(?, ?, ...) con parámetros seguros (sin concatenar texto del usuario).
 * Devuelve un arreglo con cada conjunto de resultados que hizo SELECT el procedimiento.
 *
 * Ejemplo: const [filas, [{ total }]] = await llamar('sp_listar_atractivos', [null, null, 'inca', 10, 0]);
 *
 * Por qué se filtra: mysql2 devuelve un CALL como [resultado1, resultado2, ..., ResultSetHeader],
 * y ese último elemento (información de la ejecución) no nos sirve.
 */
export async function llamar(nombre, params = []) {
  if (!NOMBRE_VALIDO.test(nombre)) throw new Error(`Nombre de procedimiento inválido: ${nombre}`);
  const marcas = params.map(() => '?').join(', ');
  const [respuesta] = await pool.query(`CALL ${nombre}(${marcas})`, params);
  return Array.isArray(respuesta) ? respuesta.filter(Array.isArray) : [];
}

/** Atajo: devuelve la primera fila del primer resultado (o undefined). */
export async function llamarUno(nombre, params = []) {
  const [filas = []] = await llamar(nombre, params);
  return filas[0];
}
