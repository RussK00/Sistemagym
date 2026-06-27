import jwt from 'jsonwebtoken';

// Middleware: verifica que la petición traiga un token JWT válido.
// Si es válido, inyecta los datos del usuario en req.usuario.
export function verificarToken(req, res, next) {
  const header = req.headers['authorization'];

  // Formato esperado: "Bearer <token>"
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token no proporcionado.' });
  }

  const token = header.split(' ')[1];

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.usuario = payload; // { id_usuario, id_socio, rol }
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Token inválido o expirado.' });
  }
}

// Middleware factory: restringe el acceso a ciertos roles.
// Uso: router.get('/ruta', verificarToken, permitirRoles('administrador'), handler)
export function permitirRoles(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.usuario.rol)) {
      return res.status(403).json({ error: 'No tienes permiso para esta acción.' });
    }
    next();
  };
}
