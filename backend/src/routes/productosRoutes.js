import { Router } from 'express';
import multer from 'multer';
import { getProductos, createProducto, updateProducto, toggleProducto, subirImagenProducto } from '../controllers/productosController.js';
import { verificarToken, permitirRoles } from '../middlewares/auth.js';

const router = Router();

// Multer en memoria, límite 5 MB (igual que la foto de perfil).
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
});

// Ver el catálogo: admin y recepcionista (el recepcionista lo necesita para vender).
// Crear/editar/desactivar: solo administrador (gestión del catálogo, HU-09).
router.get('/', verificarToken, permitirRoles('administrador', 'recepcionista'), getProductos);
router.post('/imagen', verificarToken, permitirRoles('administrador'), upload.single('imagen'), subirImagenProducto);
router.post('/',            verificarToken, permitirRoles('administrador'), createProducto);
router.put('/:id',          verificarToken, permitirRoles('administrador'), updateProducto);
router.patch('/:id/estado', verificarToken, permitirRoles('administrador'), toggleProducto);

export default router;
