import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { readFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const keyPath = join(__dirname, '..', '..', 'serviceAccountKey.json');

let fcmDisponible = false;
let messaging = null;

// Inicializa Firebase Admin si la clave de servicio existe.
if (existsSync(keyPath)) {
  try {
    const serviceAccount = JSON.parse(readFileSync(keyPath, 'utf8'));
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
  console.warn('⚠️  serviceAccountKey.json no encontrado — push deshabilitado (las notificaciones in-app siguen funcionando).');
}

export { messaging, fcmDisponible };
