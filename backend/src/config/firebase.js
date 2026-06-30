import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { readFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const keyPath = join(__dirname, '..', '..', 'serviceAccountKey.json');

let fcmDisponible = false;
let messaging = null;

// Obtiene la clave de servicio de Firebase:
//  1) desde la variable de entorno FIREBASE_SERVICE_ACCOUNT (producción / Render),
//  2) o desde el archivo serviceAccountKey.json (desarrollo local).
function obtenerServiceAccount() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (err) {
      console.error('⚠️  FIREBASE_SERVICE_ACCOUNT no es un JSON válido:', err.message);
      return null;
    }
  }
  if (existsSync(keyPath)) {
    return JSON.parse(readFileSync(keyPath, 'utf8'));
  }
  return null;
}

const serviceAccount = obtenerServiceAccount();

if (serviceAccount) {
  try {
    if (getApps().length === 0) {
      initializeApp({ credential: cert(serviceAccount) });
    }
    messaging = getMessaging();
    fcmDisponible = true;
    console.log('✅ Firebase Admin inicializado (notificaciones push activas).');
  } catch (err) {
    console.error('⚠️  No se pudo inicializar Firebase Admin:', err.message);
  }
} else {
  console.warn('⚠️  Clave de Firebase no encontrada — push deshabilitado (las notificaciones in-app siguen funcionando).');
}

export { messaging, fcmDisponible };
