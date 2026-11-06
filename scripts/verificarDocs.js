// Comprueba que Swagger documenta EXACTAMENTE las rutas que existen en src/routes (ni más ni menos).
// Uso: npm run docs:verificar
import fs from 'node:fs';
import path from 'node:path';
import { openapi } from '../src/docs/openapi.js';

const carpeta = path.resolve('src/routes');
const index = fs.readFileSync(path.join(carpeta, 'index.js'), 'utf8');

// 1) Qué router se monta en qué prefijo:  router.use('/atractivos', atractivos)
const montajes = [...index.matchAll(/router\.use\('([^']+)', (\w+)\)/g)].map(([, prefijo, nombre]) => ({ prefijo, nombre }));

// 2) Qué rutas define cada router en los archivos *.routes.js:  atractivos.get('/:id', ...)
const rutasPorRouter = {};
for (const archivo of fs.readdirSync(carpeta).filter((f) => f.endsWith('.routes.js'))) {
  const texto = fs.readFileSync(path.join(carpeta, archivo), 'utf8');
  for (const [, nombre, metodo, ruta] of texto.matchAll(/(\w+)\.(get|post|put|patch|delete)\('([^']+)'/g)) {
    const clave = nombre === 'router' ? 'authRoutes' : nombre; // auth.routes.js exporta "router" como authRoutes
    (rutasPorRouter[clave] ||= []).push([metodo, ruta]);
  }
}

const aOpenApi = (p) => p.replace(/:(\w+)/g, '{$1}').replace(/\/$/, '') || '/';
const reales = new Set(['get /health']);
for (const { prefijo, nombre } of montajes) {
  for (const [metodo, ruta] of rutasPorRouter[nombre] ?? []) {
    reales.add(`${metodo} ${aOpenApi(prefijo + (ruta === '/' ? '' : ruta))}`);
  }
}

const documentadas = new Set();
for (const [ruta, ops] of Object.entries(openapi.paths)) {
  for (const metodo of ['get', 'post', 'put', 'patch', 'delete']) if (ops[metodo]) documentadas.add(`${metodo} ${ruta}`);
}

const faltan = [...reales].filter((r) => !documentadas.has(r));
const sobran = [...documentadas].filter((d) => !reales.has(d));
const refs = [...JSON.stringify(openapi).matchAll(/"\$ref":"#\/components\/(\w+)\/(\w+)"/g)];
const rotas = [...new Set(refs.filter(([, tipo, n]) => !openapi.components[tipo]?.[n]).map(([, t, n]) => `${t}/${n}`))];

console.log(`Rutas reales: ${reales.size} · documentadas: ${documentadas.size}`);
console.log(`Sin documentar: ${faltan.join(', ') || 'ninguna'}`);
console.log(`Documentadas que no existen: ${sobran.join(', ') || 'ninguna'}`);
console.log(`Referencias $ref: ${refs.length} · rotas: ${rotas.join(', ') || 'ninguna'}`);
process.exitCode = faltan.length || sobran.length || rotas.length ? 1 : 0;
