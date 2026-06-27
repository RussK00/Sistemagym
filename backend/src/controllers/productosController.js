import { query } from '../config/db.js';
import { subirImagen } from '../services/storageService.js';

// GET /api/productos — listar todos los productos (catálogo)
export async function getProductos(req, res) {
  try {
    const result = await query(
      `SELECT id_producto, nombre, descripcion, categoria, precio, stock, activo, imagen_url
       FROM productos
       ORDER BY id_producto DESC`
    );
    return res.json(result.rows);
  } catch (err) {
    console.error('Error getProductos:', err.message);
    return res.status(500).json({ error: 'Error al obtener los productos.' });
  }
}

// POST /api/productos — crear producto
export async function createProducto(req, res) {
  const { nombre, descripcion, categoria, precio, stock, imagen_url } = req.body;
  if (!nombre || precio == null || stock == null) {
    return res.status(400).json({ error: 'Nombre, precio y stock son obligatorios.' });
  }
  try {
    const result = await query(
      `INSERT INTO productos (nombre, descripcion, categoria, precio, stock, imagen_url, activo)
       VALUES ($1, $2, $3, $4, $5, $6, TRUE)
       RETURNING id_producto, nombre, descripcion, categoria, precio, stock, activo, imagen_url`,
      [nombre.trim(), descripcion?.trim() ?? '', categoria?.trim() || 'Suplemento', precio, stock, imagen_url || null]
    );
    return res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error createProducto:', err.message);
    return res.status(500).json({ error: 'Error al crear el producto.' });
  }
}

// PUT /api/productos/:id — editar producto
export async function updateProducto(req, res) {
  const { id } = req.params;
  const { nombre, descripcion, categoria, precio, stock, imagen_url } = req.body;
  if (!nombre || precio == null || stock == null) {
    return res.status(400).json({ error: 'Nombre, precio y stock son obligatorios.' });
  }
  try {
    const result = await query(
      `UPDATE productos
       SET nombre = $1, descripcion = $2, categoria = $3, precio = $4, stock = $5, imagen_url = $6
       WHERE id_producto = $7
       RETURNING id_producto, nombre, descripcion, categoria, precio, stock, activo, imagen_url`,
      [nombre.trim(), descripcion?.trim() ?? '', categoria?.trim() || 'Suplemento', precio, stock, imagen_url || null, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Producto no encontrado.' });
    }
    return res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updateProducto:', err.message);
    return res.status(500).json({ error: 'Error al actualizar el producto.' });
  }
}

// PATCH /api/productos/:id/estado — activar / desactivar
export async function toggleProducto(req, res) {
  const { id } = req.params;
  try {
    const result = await query(
      `UPDATE productos SET activo = NOT activo
       WHERE id_producto = $1
       RETURNING id_producto, nombre, descripcion, categoria, precio, stock, activo, imagen_url`,
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Producto no encontrado.' });
    }
    return res.json(result.rows[0]);
  } catch (err) {
    console.error('Error toggleProducto:', err.message);
    return res.status(500).json({ error: 'Error al cambiar el estado.' });
  }
}

// POST /api/productos/imagen  (multipart con campo 'imagen')
// Sube la imagen a Supabase Storage y devuelve la URL pública.
export async function subirImagenProducto(req, res) {
  if (!req.file) {
    return res.status(400).json({ error: 'No se recibió ninguna imagen.' });
  }
  if (!req.file.mimetype.startsWith('image/')) {
    return res.status(400).json({ error: 'El archivo debe ser una imagen.' });
  }
  try {
    const ext = (req.file.mimetype.split('/')[1] || 'jpg').replace('jpeg', 'jpg');
    const nombre = `producto_${Date.now()}.${ext}`;
    const url = await subirImagen(req.file.buffer, nombre, req.file.mimetype);
    return res.json({ imagen_url: url });
  } catch (err) {
    console.error('Error subirImagenProducto:', err.message);
    return res.status(500).json({ error: 'Error al subir la imagen.' });
  }
}
