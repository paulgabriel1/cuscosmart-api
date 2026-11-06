// Pool de conexiones a MySQL: reutiliza conexiones en vez de abrir una por petición.
import mysql from 'mysql2/promise';
import { env } from './env.js';

export const pool = mysql.createPool({
  ...env.db,
  waitForConnections: true,
  connectionLimit: 10,
  decimalNumbers: true,   // DECIMAL llega como número (70.00 → 70), no como texto "70.00"
  dateStrings: ['DATE'],  // las fechas sin hora llegan como "2026-11-06"
  charset: 'utf8mb4',     // tildes y ñ
});
