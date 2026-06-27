import { Router } from 'express';
import { getMiMembresia, getMiAsistencia, registrarTokenFcm } from '../controllers/socioController.js';
import { getMisNotificaciones, marcarLeida } from '../controllers/notificacionesController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

// Rutas de la app del socio: solo accesibles por el rol 'socio'.
router.use(verificarToken, permitirRoles('socio'));

router.get('/mi-membresia',  getMiMembresia);
router.get('/mi-asistencia', getMiAsistencia);
router.get('/mis-notificaciones',            getMisNotificaciones);
router.patch('/notificaciones/:id/leida',    marcarLeida);
router.post('/token-fcm',                    registrarTokenFcm);

export default router;
