import { Router } from 'express';
import { getMembresias, createMembresia } from '../controllers/membresiasController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

router.use(verificarToken, permitirRoles('administrador', 'recepcionista'));

router.get('/',  getMembresias);
router.post('/', createMembresia);

export default router;
