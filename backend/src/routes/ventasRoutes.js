import { Router } from 'express';
import { getVentas, getVentasPorSocio, createVenta } from '../controllers/ventasController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

// Listar todas y registrar compra: admin y recepcionista
router.get('/',  verificarToken, permitirRoles('administrador', 'recepcionista'), getVentas);
router.post('/', verificarToken, permitirRoles('administrador', 'recepcionista'), createVenta);

// Compras de un socio: cualquier usuario autenticado
// (el controlador valida que un socio solo vea las suyas)
router.get('/socio/:id', verificarToken, getVentasPorSocio);

export default router;
