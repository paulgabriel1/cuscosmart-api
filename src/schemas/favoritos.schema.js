import { z } from 'zod';
import { id } from './comunes.js';

export const favoritoSchema = z.object({ atractivo_id: id });
