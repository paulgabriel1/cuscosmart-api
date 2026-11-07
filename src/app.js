import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env.js';
import routes from './routes/index.js';
import { openapi } from './docs/openapi.js';
import { notFound, errorHandler } from './middlewares/errorHandler.js';
import { limiteGeneral } from './middlewares/limitadores.js';
import { CARPETA_SUBIDAS } from './utils/imagenes.js';

const app = express();

// Documentación interactiva (Swagger), solo en desarrollo. Va antes de helmet() con su propia
// política de seguridad: sin "upgrade-insecure-requests" para que cargue por http://localhost.
if (!env.produccion) {
  const helmetDocs = helmet({ contentSecurityPolicy: { directives: { upgradeInsecureRequests: null } } });
  app.get('/api/v1/docs.json', (req, res) => res.json(openapi));
  app.use('/api/v1/docs', helmetDocs, swaggerUi.serve, swaggerUi.setup(openapi, {
    customSiteTitle: 'CuscoSmart IA API — Documentación',
    swaggerOptions: { persistAuthorization: true },
  }));
}

// Imágenes subidas (fotos de atractivos y de perfil). "cross-origin" deja que la web
// (localhost:5173) las muestre; nosniff impide que el navegador las trate como otra cosa.
app.use('/uploads', (req, res, next) => {
  res.set({ 'Cross-Origin-Resource-Policy': 'cross-origin', 'X-Content-Type-Options': 'nosniff' });
  next();
}, express.static(CARPETA_SUBIDAS, { maxAge: '7d', dotfiles: 'deny', index: false }));

app.use(helmet());                              // cabeceras de seguridad HTTP
app.use(cors({ origin: env.corsOrigin }));      // solo el front autorizado puede llamar a la API
app.use(express.json({ limit: '100kb' }));      // lee el cuerpo JSON (con tamaño máximo)
app.use(morgan('dev'));                         // muestra cada petición en la consola

app.use('/api/v1', limiteGeneral, routes);

app.use(notFound);      // después de todas las rutas: lo que no coincidió es 404
app.use(errorHandler);  // siempre el último: atrapa cualquier error lanzado antes

export default app;
