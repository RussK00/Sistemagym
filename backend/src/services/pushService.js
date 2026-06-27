import { messaging, fcmDisponible } from '../config/firebase.js';
import { query } from '../config/db.js';

// Envía una notificación push a todos los dispositivos de un socio.
// Devuelve cuántos envíos fueron exitosos.
export async function enviarPushASocio(idSocio, titulo, mensaje) {
  if (!fcmDisponible) return 0;

  // 1. Obtener los tokens del socio
  const res = await query('SELECT token FROM tokens_fcm WHERE id_socio = $1', [idSocio]);
  const tokens = res.rows.map((r) => r.token);
  if (tokens.length === 0) return 0;

  // 2. Construir y enviar el mensaje a cada token
  const message = {
    notification: { title: titulo, body: mensaje },
    tokens,
  };

  try {
    const resp = await messaging.sendEachForMulticast(message);

    // 3. Limpiar tokens inválidos (dispositivos que desinstalaron / expiraron)
    const invalidos = [];
    resp.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error?.code ?? '';
        if (code.includes('registration-token-not-registered') || code.includes('invalid-argument')) {
          invalidos.push(tokens[i]);
        }
      }
    });
    for (const t of invalidos) {
      await query('DELETE FROM tokens_fcm WHERE token = $1', [t]);
    }

    console.log(`📲 Push a socio ${idSocio}: ${resp.successCount} enviado(s), ${resp.failureCount} fallido(s).`);
    return resp.successCount;
  } catch (err) {
    console.error('Error enviando push:', err.message);
    return 0;
  }
}
