// Actualiza la base existente SIN borrar datos: columnas nuevas + procedimientos nuevos.
// Uso:  npm run db:migrar     (MySQL de XAMPP encendido)
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const carpeta = path.resolve('database');
const partes = ['migracion.sql', 'logica.sql', 'usuario.sql', 'verificacion.sql'];
const MYSQL = process.env.MYSQL_BIN || 'C:\\xampp\\mysql\\bin\\mysql.exe';

const contenido = partes.map((p) => `\n-- >>> ${p}\n${fs.readFileSync(path.join(carpeta, p), 'utf8')}`).join('\n');
const r = spawnSync(MYSQL, ['-u', 'root', '--default-character-set=utf8mb4'], { input: contenido, encoding: 'utf8' });
if (r.error) {
  console.error(`❌ No se encontró MySQL en ${MYSQL}. Define MYSQL_BIN con la ruta correcta.`);
  process.exit(1);
}
if (r.status !== 0) {
  console.error('❌ Error al migrar:\n', r.stderr);
  process.exit(1);
}
console.log(r.stdout.trim().split('\n').slice(-8).join('\n'));
console.log('✅ Base cuscosmart_db actualizada (tus datos se mantienen). Reinicia la API si estaba encendida.');
