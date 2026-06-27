import { pool, query } from '../config/db.js';

// Consulta base con nombres de socio y producto
const SELECT_VENTAS = `
  SELECT v.id_venta, v.id_socio,
         s.nombres || ' ' || s.apellidos AS nombre_socio,
         v.id_producto, p.nombre AS nombre_producto,
         v.cantidad, v.precio_unitario, v.total, v.fecha_venta
  FROM ventas v
  JOIN socios s    ON s.id_socio = v.id_socio
  JOIN productos p ON p.id_producto = v.id_producto
`;

// GET /api/ventas — todas las compras
export async function getVentas(req, res) {
  try {
    const result = await query(`${SELECT_VENTAS} ORDER BY v.fecha_venta DESC, v.id_venta DESC`);
    return res.json(result.rows);
  } catch (err) {
    console.error('Error getVentas:', err.message);
    return res.status(500).json({ error: 'Error al obtener las compras.' });
  }
}

// GET /api/ventas/socio/:id — compras de un socio (HU-11 / HU-12)
export async function getVentasPorSocio(req, res) {
  const { id } = req.params;

  // Un socio solo puede ver sus propias compras
  if (req.usuario.rol === 'socio' && req.usuario.id_socio !== Number(id)) {
    return res.status(403).json({ error: 'No puedes ver las compras de otro socio.' });
  }

  try {
    const result = await query(
      `${SELECT_VENTAS} WHERE v.id_socio = $1 ORDER BY v.fecha_venta DESC, v.id_venta DESC`, [id]);
    return res.json(result.rows);
  } catch (err) {
    console.error('Error getVentasPorSocio:', err.message);
    return res.status(500).json({ error: 'Error al obtener las compras del socio.' });
  }
}

// POST /api/ventas — registrar compra y descontar stock (transacción)
// Body: { id_socio, id_producto, cantidad }
export async function createVenta(req, res) {
  const { id_socio, id_producto, cantidad } = req.body;
  if (!id_socio || !id_producto || !cantidad || cantidad <= 0) {
    return res.status(400).json({ error: 'Faltan datos obligatorios (socio, producto, cantidad).' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Obtener el producto y bloquear la fila (evita ventas simultáneas sobre el mismo stock)
    const prodRes = await client.query(
      'SELECT nombre, precio, stock, activo FROM productos WHERE id_producto = $1 FOR UPDATE', [id_producto]);
    if (prodRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Producto no encontrado.' });
    }
    const prod = prodRes.rows[0];

    // 2. Validaciones de negocio
    if (!prod.activo) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'El producto no está disponible.' });
    }
    if (prod.stock < cantidad) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: `Stock insuficiente. Solo quedan ${prod.stock} unidades.` });
    }

    const precioUnitario = prod.precio;
    const total = (precioUnitario * cantidad).toFixed(2);

    // 3. Insertar la venta
    const ventaRes = await client.query(
      `INSERT INTO ventas (id_socio, id_producto, cantidad, precio_unitario, total, registrado_por)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id_venta`,
      [id_socio, id_producto, cantidad, precioUnitario, total, req.usuario.id_usuario]
    );

    // 4. Descontar el stock
    await client.query(
      'UPDATE productos SET stock = stock - $1 WHERE id_producto = $2', [cantidad, id_producto]);

    await client.query('COMMIT');

    // 5. Devolver la venta con nombres
    const full = await query(
      `${SELECT_VENTAS} WHERE v.id_venta = $1`, [ventaRes.rows[0].id_venta]);
    return res.status(201).json(full.rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error createVenta:', err.message);
    return res.status(500).json({ error: 'Error al registrar la compra.' });
  } finally {
    client.release();
  }
}
