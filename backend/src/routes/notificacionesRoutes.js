import { Router } from 'express';
import { generarManual } from '../controllers/notificacionesController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

// Disparar la generación de notificaciones manualmente (para pruebas/demo).
// El cron job hace esto automáticamente cada día.
router.post('/generar', verificarToken, permitirRoles('administrador', 'recepcionista'), generarManual);

export default router;
