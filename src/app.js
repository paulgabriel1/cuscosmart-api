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

app.use(helmet());                              // cabeceras de seguridad HTTP
app.use(cors({ origin: env.corsOrigin }));      // solo el front autorizado puede llamar a la API
app.use(express.json({ limit: '100kb' }));      // lee el cuerpo JSON (con tamaño máximo)
app.use(morgan('dev'));                         // muestra cada petición en la consola

app.use('/api/v1', limiteGeneral, routes);

app.use(notFound);      // después de todas las rutas: lo que no coincidió es 404
app.use(errorHandler);  // siempre el último: atrapa cualquier error lanzado antes

export default app;
