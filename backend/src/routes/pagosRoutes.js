import { Router } from 'express';
import { getPagos, createPago } from '../controllers/pagosController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

router.use(verificarToken, permitirRoles('administrador', 'recepcionista'));

router.get('/',  getPagos);
router.post('/', createPago);

export default router;
