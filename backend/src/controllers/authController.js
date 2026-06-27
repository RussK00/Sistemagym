import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { query } from '../config/db.js';
import { subirImagen } from '../services/storageService.js';

// POST /api/auth/login
// Body: { correo, password }
export async function login(req, res) {
  const { correo, password } = req.body;

  // Validación básica
  if (!correo || !password) {
    return res.status(400).json({ error: 'Correo y contraseña son obligatorios.' });
  }

  try {
    // 1. Buscar el usuario por correo
    const result = await query(
      'SELECT id_usuario, id_socio, nombre, correo, contrasena_hash, rol, activo, foto_url FROM usuarios WHERE correo = $1',
      [correo.trim().toLowerCase()]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Correo o contraseña incorrectos.' });
    }

    const usuario = result.rows[0];

    // 2. Verificar que la cuenta esté activa
    if (!usuario.activo) {
      return res.status(403).json({ error: 'Esta cuenta está desactivada. Contacta al administrador.' });
    }

    // 3. Comparar la contraseña con el hash bcrypt
    const passwordValida = await bcrypt.compare(password, usuario.contrasena_hash);
    if (!passwordValida) {
      return res.status(401).json({ error: 'Correo o contraseña incorrectos.' });
    }

    // 4. Generar el token JWT con los datos del usuario
    const token = jwt.sign(
      {
        id_usuario: usuario.id_usuario,
        id_socio:   usuario.id_socio,
        rol:        usuario.rol,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '8h' }
    );

    // 5. Devolver el token + datos del usuario (sin el hash)
    return res.json({
      token,
      usuario: {
        id_usuario: usuario.id_usuario,
        id_socio:   usuario.id_socio,
        nombre:     usuario.nombre,
        correo:     usuario.correo,
        rol:        usuario.rol,
        foto_url:   usuario.foto_url,
      },
    });
  } catch (err) {
    console.error('Error en login:', err.message);
    return res.status(500).json({ error: 'Error interno del servidor.' });
  }
}

// GET /api/auth/me  (requiere token) — devuelve el usuario completo y actual
// Se usa para restaurar la sesión ("Recordarme") validando el token.
export async function me(req, res) {
  try {
    const r = await query(
      'SELECT id_usuario, id_socio, nombre, correo, rol, activo, foto_url, fecha_creacion FROM usuarios WHERE id_usuario = $1',
      [req.usuario.id_usuario]
    );
    if (r.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado.' });
    }
    const u = r.rows[0];
    if (!u.activo) {
      return res.status(403).json({ error: 'Esta cuenta está desactivada.' });
    }
    return res.json({
      usuario: {
        id_usuario:     u.id_usuario,
        id_socio:       u.id_socio,
        nombre:         u.nombre,
        correo:         u.correo,
        rol:            u.rol,
        activo:         u.activo,
        foto_url:       u.foto_url,
        fecha_creacion: u.fecha_creacion,
      },
    });
  } catch (err) {
    console.error('Error en me:', err.message);
    return res.status(500).json({ error: 'Error al obtener el usuario.' });
  }
}

// POST /api/auth/foto  (requiere token, multipart con campo 'foto')
// Sube la foto de perfil a Supabase Storage y guarda la URL.
export async function subirFotoPerfil(req, res) {
  if (!req.file) {
    return res.status(400).json({ error: 'No se recibió ninguna imagen.' });
  }

  // Validar que sea una imagen
  if (!req.file.mimetype.startsWith('image/')) {
    return res.status(400).json({ error: 'El archivo debe ser una imagen.' });
  }

  try {
    // Nombre único: usuario_<id>_<timestamp>.<ext>
    const ext = (req.file.mimetype.split('/')[1] || 'jpg').replace('jpeg', 'jpg');
    const nombre = `usuario_${req.usuario.id_usuario}_${Date.now()}.${ext}`;

    // Subir a Storage
    const url = await subirImagen(req.file.buffer, nombre, req.file.mimetype);

    // Guardar la URL en la BD
    await query('UPDATE usuarios SET foto_url = $1 WHERE id_usuario = $2',
      [url, req.usuario.id_usuario]);

    return res.json({ foto_url: url });
  } catch (err) {
    console.error('Error subirFotoPerfil:', err.message);
    return res.status(500).json({ error: 'Error al subir la foto.' });
  }
}

// PATCH /api/auth/cambiar-password  (requiere token)
// Body: { actual, nueva }
export async function cambiarPassword(req, res) {
  const { actual, nueva } = req.body;

  if (!actual || !nueva) {
    return res.status(400).json({ error: 'Debes ingresar la contraseña actual y la nueva.' });
  }
  if (nueva.length < 6) {
    return res.status(400).json({ error: 'La nueva contraseña debe tener al menos 6 caracteres.' });
  }

  try {
    const result = await query(
      'SELECT contrasena_hash FROM usuarios WHERE id_usuario = $1', [req.usuario.id_usuario]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado.' });
    }

    // Verificar la contraseña actual
    const valida = await bcrypt.compare(actual, result.rows[0].contrasena_hash);
    if (!valida) {
      return res.status(401).json({ error: 'La contraseña actual es incorrecta.' });
    }

    // Guardar la nueva (hasheada)
    const nuevoHash = await bcrypt.hash(nueva, 10);
    await query(
      'UPDATE usuarios SET contrasena_hash = $1 WHERE id_usuario = $2',
      [nuevoHash, req.usuario.id_usuario]);

    return res.json({ message: 'Contraseña actualizada correctamente.' });
  } catch (err) {
    console.error('Error cambiarPassword:', err.message);
    return res.status(500).json({ error: 'Error al cambiar la contraseña.' });
  }
}
