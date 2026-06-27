import dotenv from 'dotenv';
dotenv.config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_KEY  = process.env.SUPABASE_SERVICE_KEY;
const BUCKET       = 'avatars';

// Sube una imagen al bucket de Supabase Storage y devuelve su URL pública.
// buffer: contenido del archivo | nombre: ruta dentro del bucket | tipo: mime
export async function subirImagen(buffer, nombre, tipo) {
  if (!SUPABASE_URL || !SERVICE_KEY) {
    throw new Error('Storage no configurado (faltan SUPABASE_URL / SUPABASE_SERVICE_KEY).');
  }

  const res = await fetch(`${SUPABASE_URL}/storage/v1/object/${BUCKET}/${nombre}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SERVICE_KEY}`,
      'Content-Type': tipo || 'image/jpeg',
      'x-upsert': 'true', // sobrescribe si ya existe (para reemplazar la foto)
    },
    body: buffer,
  });

  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Error al subir a Storage: ${res.status} ${txt}`);
  }

  // URL pública (el bucket es público)
  return `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${nombre}`;
}
