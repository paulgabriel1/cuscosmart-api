// Lee el archivo .env UNA sola vez y valida que no falte nada.
// Si falta una variable, la API no arranca (mejor fallar al inicio que a mitad de una petición).
import 'dotenv/config';

const OBLIGATORIAS = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME', 'JWT_SECRET'];

const faltan = OBLIGATORIAS.filter((nombre) => !process.env[nombre]);
if (faltan.length > 0) {
  console.error(`❌ Faltan variables en el archivo .env: ${faltan.join(', ')}`);
  console.error('   Copia .env.example como .env y complétalo.');
  process.exit(1);
}
if (process.env.JWT_SECRET.length < 32) {
  console.error('❌ JWT_SECRET es muy corto (mínimo 32 caracteres). Genera uno con:');
  console.error("   node -e \"console.log(require('crypto').randomBytes(48).toString('hex'))\"");
  process.exit(1);
}

export const env = {
  produccion: process.env.NODE_ENV === 'production',
  port: Number(process.env.PORT || 3000),
  db: {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '8h',
  },
  corsOrigin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  // Opcional: sin este valor el botón "Continuar con Google" no se activa
  googleClientId: process.env.GOOGLE_CLIENT_ID || '',
};
