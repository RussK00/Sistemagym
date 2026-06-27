// ╔══════════════════════════════════════════════════════════════════╗
// ║  Script de datos iniciales (seed) para StanleyGym.                 ║
// ║  Inserta planes, productos, configuración y usuarios de prueba.    ║
// ║  Las contraseñas se encriptan con bcrypt antes de guardarse.       ║
// ║                                                                    ║
// ║  Ejecutar con:  node src/seed.js                                   ║
// ╚══════════════════════════════════════════════════════════════════╝

import bcrypt from 'bcrypt';
import { pool } from './config/db.js';

const SALT_ROUNDS = 10;

async function seed() {
  const client = await pool.connect();
  try {
    console.log('🌱 Iniciando carga de datos...\n');

    // Limpiar datos previos (respetando dependencias)
    await client.query('TRUNCATE ventas, pagos, asistencia, membresias, usuarios, socios, planes, productos, configuracion RESTART IDENTITY CASCADE');

    // ─── PLANES ──────────────────────────────────────────────────────
    await client.query(`
      INSERT INTO planes (nombre, duracion_dias, precio, descripcion) VALUES
      ('Mensual',    30,  80,  'Acceso por 30 días'),
      ('Trimestral', 90,  200, 'Acceso por 90 días'),
      ('Anual',      365, 700, 'Acceso por 365 días')
    `);
    console.log('✅ Planes insertados');

    // ─── PRODUCTOS (suplementos) ─────────────────────────────────────
    await client.query(`
      INSERT INTO productos (nombre, descripcion, precio, stock, activo) VALUES
      ('Proteína Whey 2kg',            'Proteína de suero, sabor chocolate', 180, 24, true),
      ('Creatina Monohidratada 300g',  'Mejora fuerza y rendimiento',        90,  15, true),
      ('BCAA 250g',                    'Aminoácidos de cadena ramificada',   75,  0,  true),
      ('Pre-entreno 30 dosis',         'Energía y enfoque pre-entrenamiento',120, 8,  true),
      ('Shaker 600ml',                 'Vaso mezclador con rejilla',         25,  40, false)
    `);
    console.log('✅ Productos insertados');

    // ─── CONFIGURACIÓN ───────────────────────────────────────────────
    await client.query(`
      INSERT INTO configuracion (id, dias_anticipacion, notificaciones_activas)
      VALUES (1, 3, true)
    `);
    console.log('✅ Configuración insertada');

    // ─── SOCIOS de ejemplo ───────────────────────────────────────────
    const socios = await client.query(`
      INSERT INTO socios (nombres, apellidos, dni, telefono, correo, fecha_registro, estado) VALUES
      ('Carlos', 'Ríos Pérez',   '45123678', '965432100', 'carlos.rios@gmail.com',    '2025-01-10', 'activo'),
      ('María',  'Torres Lomas',  '52876543', '974321987', 'maria.torres@hotmail.com', '2025-02-14', 'activo'),
      ('Jhon',   'Sánchez Ruiz',  '61234987', '956789012', 'jhon.sanchez@gmail.com',   '2025-03-05', 'inactivo')
      RETURNING id_socio
    `);
    console.log('✅ Socios insertados');

    const idCarlos = socios.rows[0].id_socio;

    // ─── USUARIOS (con contraseñas encriptadas) ──────────────────────
    const hashAdmin   = await bcrypt.hash('admin123',  SALT_ROUNDS);
    const hashRecep   = await bcrypt.hash('recep123',  SALT_ROUNDS);
    const hashSocio   = await bcrypt.hash('socio123',  SALT_ROUNDS);

    await client.query(`
      INSERT INTO usuarios (id_socio, nombre, correo, contrasena_hash, rol, activo) VALUES
      (NULL,       'Administrador',       'admin@stanleygym.pe',         $1, 'administrador', true),
      (NULL,       'Recepcionista',       'recepcionista@stanleygym.pe', $2, 'recepcionista', true),
      ($3,         'Carlos Ríos Pérez',   'carlos.rios@gmail.com',       $4, 'socio',         true)
    `, [hashAdmin, hashRecep, idCarlos, hashSocio]);
    console.log('✅ Usuarios insertados (contraseñas encriptadas con bcrypt)');

    // ─── MEMBRESÍAS de ejemplo ───────────────────────────────────────
    await client.query(`
      INSERT INTO membresias (id_socio, id_plan, fecha_inicio, fecha_vencimiento, estado) VALUES
      ($1, 1, CURRENT_DATE - 20, CURRENT_DATE + 10, 'activa')
    `, [idCarlos]);
    console.log('✅ Membresía de ejemplo insertada');

    console.log('\n🎉 Datos iniciales cargados correctamente.\n');
    console.log('   Credenciales de prueba (contraseña):');
    console.log('   • admin@stanleygym.pe         → admin123');
    console.log('   • recepcionista@stanleygym.pe → recep123');
    console.log('   • carlos.rios@gmail.com       → socio123\n');
  } catch (err) {
    console.error('❌ Error al cargar datos:', err.message);
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
