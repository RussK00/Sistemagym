import { Router } from 'express';
import { getIngresosHoy, registrarIngreso } from '../controllers/asistenciaController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

router.use(verificarToken, permitirRoles('administrador', 'recepcionista'));

router.get('/hoy', getIngresosHoy);
router.post('/',   registrarIngreso);

export default router;
