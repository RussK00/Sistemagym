import { Router } from 'express';
import {
  getConfiguracion, updateConfiguracion,
  getRecepcionistas, crearRecepcionista, toggleRecepcionista, eliminarRecepcionista,
} from '../controllers/configuracionController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

// La configuración del sistema es exclusiva del administrador.
router.use(verificarToken, permitirRoles('administrador'));

router.get('/', getConfiguracion);
router.put('/', updateConfiguracion);

// Gestión de cuentas de recepcionista (HU-13)
router.get('/recepcionistas',              getRecepcionistas);
router.post('/recepcionistas',             crearRecepcionista);
router.patch('/recepcionistas/:id/estado', toggleRecepcionista);
router.delete('/recepcionistas/:id',       eliminarRecepcionista);

export default router;
