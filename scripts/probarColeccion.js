// Ejecuta la colección de Postman desde la consola (como el Runner de Postman) y resume el resultado.
// Uso: npm run test:api      (antes: npm run db:reset y reiniciar la API)
// Soporta lo que usa nuestra colección: pm.test, pm.expect(...).to.eql / include / be.above,
// pm.response, pm.collectionVariables y pm.sendRequest.
import fs from 'node:fs';
import { isDeepStrictEqual } from 'node:util';

const ruta = process.argv[2] || 'postman/cuscosmart.collection.json';
const col = JSON.parse(fs.readFileSync(ruta, 'utf8'));
const vars = Object.fromEntries(col.variable.map((v) => [v.key, v.value]));
const sustituir = (s) => s.replace(/\{\{(\w+)\}\}/g, (_, k) => String(vars[k] ?? ''));

function expect(actual, negar = false) {
  const comprobar = (ok, msg) => { if (ok === negar) throw new Error(msg); };
  const api = {
    eql: (x) => comprobar(isDeepStrictEqual(actual, x), `esperaba ${JSON.stringify(x)}, llegó ${JSON.stringify(actual)}`),
    include: (x) => comprobar(actual.includes(x), `esperaba que ${JSON.stringify(actual)} incluya ${JSON.stringify(x)}`),
    be: { above: (n) => comprobar(actual > n, `${actual} no es mayor que ${n}`) },
  };
  api.not = negar ? api : expect(actual, true).to;
  return { to: api };
}

async function enviar({ url, method, headers, body }) {
  const res = await fetch(url, { method, headers, body });
  const texto = await res.text();
  return { code: res.status, json: () => JSON.parse(texto), text: texto };
}

async function ejecutarScript(lineas, respuesta) {
  const resultados = [];
  const pendientes = [];
  const pm = {
    test: (nombre, fn) => {
      try { fn(); resultados.push([true, nombre]); } catch (e) { resultados.push([false, `${nombre}: ${e.message}`]); }
    },
    expect,
    collectionVariables: { get: (k) => vars[k], set: (k, v) => { vars[k] = v; } },
    sendRequest: (r, cb) => pendientes.push(
      enviar({ url: r.url, method: r.method, headers: r.header, body: r.body?.raw }).then((x) => cb(null, x)),
    ),
    response: respuesta && {
      code: respuesta.code,
      json: respuesta.json,
      to: { have: { status: (n) => { if (respuesta.code !== n) throw new Error(`esperaba ${n}, llegó ${respuesta.code}`); } } },
    },
  };
  new Function('pm', lineas.join('\n'))(pm);
  await Promise.all(pendientes);
  return resultados;
}

const preColeccion = col.event?.find((e) => e.listen === 'prerequest')?.script.exec ?? [];
let aprobadas = 0;
let fallidas = 0;
let peticiones = 0;

for (const carpeta of col.item) {
  console.log(`\n== ${carpeta.name}`);
  for (const item of carpeta.item) {
    await ejecutarScript(preColeccion);
    const pre = item.event.find((e) => e.listen === 'prerequest');
    if (pre) await ejecutarScript(pre.script.exec);

    const r = item.request;
    const headers = Object.fromEntries(r.header.map((h) => [h.key, h.value]));
    if (r.auth?.type === 'bearer') headers.Authorization = `Bearer ${sustituir(r.auth.bearer[0].value)}`;
    const respuesta = await enviar({ url: sustituir(r.url.raw), method: r.method, headers, body: r.body && sustituir(r.body.raw) });
    const resultados = await ejecutarScript(item.event.find((e) => e.listen === 'test').script.exec, respuesta);

    const malas = resultados.filter(([ok]) => !ok);
    aprobadas += resultados.length - malas.length;
    fallidas += malas.length;
    peticiones += 1;
    console.log(`${malas.length ? 'XX' : 'OK'} [${respuesta.code}] ${item.name}`);
    malas.forEach(([, msg]) => console.log(`     ✗ ${msg}`));
  }
}

console.log(`\nPeticiones: ${peticiones} · Pruebas: ${aprobadas} aprobadas, ${fallidas} fallidas`);
process.exitCode = fallidas ? 1 : 0;
