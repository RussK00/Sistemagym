import { Router } from 'express';
import { getAsistenciaMensual, getEstadoMembresias, getDashboard } from '../controllers/reportesController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

// Los reportes son exclusivos del administrador (HU-06).
router.use(verificarToken, permitirRoles('administrador'));

router.get('/dashboard',  getDashboard);
router.get('/asistencia', getAsistenciaMensual);
router.get('/membresias', getEstadoMembresias);

export default router;
