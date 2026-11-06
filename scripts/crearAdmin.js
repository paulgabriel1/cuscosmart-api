// Crea un usuario ADMIN desde la consola (no hay registro público de administradores).
// Uso: npm run admin -- "Nombre Completo" correo@dominio.com "Contraseña123"
import bcrypt from 'bcryptjs';
import { pool } from '../src/config/db.js';
import { llamarUno } from '../src/utils/sp.js';

const [nombre, correo, contrasena] = process.argv.slice(2);

if (!nombre || !correo || !contrasena) {
  console.log('Uso: npm run admin -- "Nombre Completo" correo@dominio.com "Contraseña123"');
  process.exit(1);
}
if (contrasena.length < 8 || !/[A-Za-z]/.test(contrasena) || !/[0-9]/.test(contrasena)) {
  console.error('❌ La contraseña debe tener mínimo 8 caracteres, con letras y números.');
  process.exit(1);
}

try {
  const hash = await bcrypt.hash(contrasena, 10);
  const { usuario_id } = await llamarUno('sp_registrar_usuario', [nombre, correo.toLowerCase(), hash, null]);
  const admin = await llamarUno('sp_cambiar_rol_usuario', [usuario_id, 'ADMIN']);
  console.log(`✅ Administrador creado: ${admin.nombre_completo} <${admin.correo}> (id ${admin.id})`);
} catch (e) {
  console.error('❌', e.sqlMessage || e.message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
