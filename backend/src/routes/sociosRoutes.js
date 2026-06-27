import { Router } from 'express';
import { getSocios, createSocio, updateSocio, toggleEstado } from '../controllers/sociosController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

// Todas las rutas de socios requieren token válido.
// Solo administrador y recepcionista pueden gestionar socios (no el socio).
router.use(verificarToken, permitirRoles('administrador', 'recepcionista'));

router.get('/',             getSocios);
router.post('/',            createSocio);
router.put('/:id',          updateSocio);
router.patch('/:id/estado', toggleEstado);

export default router;
