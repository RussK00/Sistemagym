import { Router } from 'express';
import { getPlanes, createPlan, updatePlan, togglePlan, deletePlan } from '../controllers/planesController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

// Ver planes: admin y recepcionista (el recepcionista los usa para asignar membresías).
router.get('/', verificarToken, permitirRoles('administrador', 'recepcionista'), getPlanes);

// Gestionar planes: solo administrador.
router.post('/',            verificarToken, permitirRoles('administrador'), createPlan);
router.put('/:id',          verificarToken, permitirRoles('administrador'), updatePlan);
router.patch('/:id/estado', verificarToken, permitirRoles('administrador'), togglePlan);
router.delete('/:id',       verificarToken, permitirRoles('administrador'), deletePlan);

export default router;
