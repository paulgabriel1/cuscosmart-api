import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env.js';
import routes from './routes/index.js';
import { notFound, errorHandler } from './middlewares/errorHandler.js';

const app = express();

app.use(helmet());                              // cabeceras de seguridad HTTP
app.use(cors({ origin: env.corsOrigin }));      // solo el front autorizado puede llamar a la API
app.use(express.json({ limit: '100kb' }));      // lee el cuerpo JSON (con tamaño máximo)
app.use(morgan('dev'));                         // muestra cada petición en la consola

app.use('/api/v1', routes);

app.use(notFound);      // después de todas las rutas: lo que no coincidió es 404
app.use(errorHandler);  // siempre el último: atrapa cualquier error lanzado antes

export default app;
