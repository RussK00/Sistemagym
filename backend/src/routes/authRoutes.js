import { Router } from 'express';
import multer from 'multer';
import { login, me, cambiarPassword, subirFotoPerfil } from '../controllers/authController.js';
import { verificarToken } from '../middlewares/auth.js';

const router = Router();

// Multer en memoria, límite 5 MB
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
});

// POST /api/auth/login — iniciar sesión
router.post('/login', login);

// GET /api/auth/me — datos del usuario autenticado (requiere token)
router.get('/me', verificarToken, me);

// PATCH /api/auth/cambiar-password — cambiar la propia contraseña
router.patch('/cambiar-password', verificarToken, cambiarPassword);

// POST /api/auth/foto — subir foto de perfil (campo 'foto')
router.post('/foto', verificarToken, upload.single('foto'), subirFotoPerfil);

export default router;
