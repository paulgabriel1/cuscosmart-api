// Une los archivos de database/ en cuscosmart_todo.sql (en el orden correcto).
// Uso:  npm run db:armar          → solo arma el archivo
//       npm run db:reset          → lo arma y lo importa en MySQL como root (borra y recrea la base)
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const carpeta = path.resolve('database');
const partes = ['schema.sql', 'logica.sql', 'seed.sql', 'usuario.sql', 'verificacion.sql'];
const MYSQL = process.env.MYSQL_BIN || 'C:\\xampp\\mysql\\bin\\mysql.exe';

const cabecera = [
  '-- =====================================================================',
  '--  CuscoSmart IA · cuscosmart_todo.sql (ARCHIVO GENERADO: no editar a mano)',
  '--  Une schema + logica + seed + usuario + verificacion. Se arma con: npm run db:armar',
  '-- =====================================================================',
].join('\n');

const contenido = [cabecera, ...partes.map((p) => `\n-- >>> ${p}\n${fs.readFileSync(path.join(carpeta, p), 'utf8')}`)].join('\n');
fs.writeFileSync(path.join(carpeta, 'cuscosmart_todo.sql'), contenido);
console.log(`✅ database/cuscosmart_todo.sql armado (${partes.length} archivos)`);

if (process.argv.includes('--importar')) {
  const r = spawnSync(MYSQL, ['-u', 'root', '--default-character-set=utf8mb4'], { input: contenido, encoding: 'utf8' });
  if (r.error) {
    console.error(`❌ No se encontró MySQL en ${MYSQL}. Define MYSQL_BIN con la ruta correcta.`);
    process.exit(1);
  }
  if (r.status !== 0) {
    console.error('❌ Error al importar:\n', r.stderr);
    process.exit(1);
  }
  console.log(r.stdout.trim().split('\n').slice(-8).join('\n'));
  console.log('✅ Base cuscosmart_db recreada. Reinicia la API si estaba encendida.');
}
