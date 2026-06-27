-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  StanleyGym App — Esquema de base de datos (PostgreSQL / Supabase)  ║
-- ║  Basado en la sección 6.3 de la documentación del proyecto.        ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- Limpieza previa (orden inverso por dependencias)
DROP TABLE IF EXISTS ventas       CASCADE;
DROP TABLE IF EXISTS productos     CASCADE;
DROP TABLE IF EXISTS pagos         CASCADE;
DROP TABLE IF EXISTS asistencia    CASCADE;
DROP TABLE IF EXISTS membresias    CASCADE;
DROP TABLE IF EXISTS planes        CASCADE;
DROP TABLE IF EXISTS usuarios      CASCADE;
DROP TABLE IF EXISTS socios        CASCADE;
DROP TABLE IF EXISTS configuracion CASCADE;

-- ─── SOCIOS ──────────────────────────────────────────────────────────
CREATE TABLE socios (
  id_socio        SERIAL PRIMARY KEY,
  nombres         VARCHAR(100) NOT NULL,
  apellidos       VARCHAR(100) NOT NULL,
  dni             VARCHAR(8)   NOT NULL UNIQUE,
  telefono        VARCHAR(15),
  correo          VARCHAR(150),
  fecha_registro  DATE         NOT NULL DEFAULT CURRENT_DATE,
  estado          VARCHAR(10)  NOT NULL DEFAULT 'activo'
                   CHECK (estado IN ('activo', 'inactivo')),
  foto_url        TEXT
);

-- ─── USUARIOS (credenciales de acceso) ───────────────────────────────
CREATE TABLE usuarios (
  id_usuario       SERIAL PRIMARY KEY,
  id_socio         INTEGER REFERENCES socios(id_socio) ON DELETE SET NULL,
  nombre           VARCHAR(150) NOT NULL,
  correo           VARCHAR(150) NOT NULL UNIQUE,
  contrasena_hash  TEXT         NOT NULL,
  rol              VARCHAR(15)  NOT NULL
                    CHECK (rol IN ('administrador', 'recepcionista', 'socio')),
  activo           BOOLEAN      NOT NULL DEFAULT TRUE,
  fecha_creacion   TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ─── PLANES de membresía ─────────────────────────────────────────────
CREATE TABLE planes (
  id_plan        SERIAL PRIMARY KEY,
  nombre         VARCHAR(50)  NOT NULL,
  duracion_dias  INTEGER      NOT NULL CHECK (duracion_dias > 0),
  precio         NUMERIC(8,2) NOT NULL CHECK (precio >= 0),
  descripcion    TEXT,
  activo         BOOLEAN      NOT NULL DEFAULT TRUE
);

-- ─── MEMBRESÍAS ──────────────────────────────────────────────────────
CREATE TABLE membresias (
  id_membresia      SERIAL PRIMARY KEY,
  id_socio          INTEGER NOT NULL REFERENCES socios(id_socio) ON DELETE CASCADE,
  id_plan           INTEGER NOT NULL REFERENCES planes(id_plan),
  fecha_inicio      DATE    NOT NULL,
  fecha_vencimiento DATE    NOT NULL,
  estado            VARCHAR(12) NOT NULL DEFAULT 'activa'
                     CHECK (estado IN ('activa', 'vencida', 'suspendida'))
);

-- ─── ASISTENCIA (check-in) ───────────────────────────────────────────
CREATE TABLE asistencia (
  id_asistencia       SERIAL PRIMARY KEY,
  id_socio            INTEGER NOT NULL REFERENCES socios(id_socio) ON DELETE CASCADE,
  fecha_hora_ingreso  TIMESTAMP NOT NULL DEFAULT NOW(),
  registrado_por      INTEGER REFERENCES usuarios(id_usuario)
);

-- ─── PAGOS ───────────────────────────────────────────────────────────
CREATE TABLE pagos (
  id_pago        SERIAL PRIMARY KEY,
  id_membresia   INTEGER REFERENCES membresias(id_membresia) ON DELETE SET NULL,
  id_socio       INTEGER NOT NULL REFERENCES socios(id_socio) ON DELETE CASCADE,
  concepto       VARCHAR(150) NOT NULL,
  monto          NUMERIC(8,2) NOT NULL CHECK (monto >= 0),
  fecha_pago     DATE         NOT NULL DEFAULT CURRENT_DATE,
  metodo_pago    VARCHAR(15)  NOT NULL
                  CHECK (metodo_pago IN ('efectivo', 'transferencia')),
  observaciones  TEXT,
  registrado_por INTEGER REFERENCES usuarios(id_usuario)
);

-- ─── PRODUCTOS (suplementos, bebidas, agua, accesorios, etc.) ─────────
CREATE TABLE productos (
  id_producto  SERIAL PRIMARY KEY,
  nombre       VARCHAR(100) NOT NULL,
  descripcion  TEXT,
  categoria    VARCHAR(20)  NOT NULL DEFAULT 'Suplemento', -- Suplemento | Bebida | Accesorio | Otro
  precio       NUMERIC(8,2) NOT NULL CHECK (precio >= 0),
  stock        INTEGER      NOT NULL DEFAULT 0 CHECK (stock >= 0),
  imagen_url   TEXT,        -- foto del producto (Supabase Storage), opcional
  activo       BOOLEAN      NOT NULL DEFAULT TRUE
);

-- ─── VENTAS (compras de suplementos) ─────────────────────────────────
CREATE TABLE ventas (
  id_venta        SERIAL PRIMARY KEY,
  id_socio        INTEGER NOT NULL REFERENCES socios(id_socio) ON DELETE CASCADE,
  id_producto     INTEGER NOT NULL REFERENCES productos(id_producto),
  cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
  precio_unitario NUMERIC(8,2) NOT NULL CHECK (precio_unitario >= 0),
  total           NUMERIC(10,2) NOT NULL CHECK (total >= 0),
  fecha_venta     DATE    NOT NULL DEFAULT CURRENT_DATE,
  registrado_por  INTEGER REFERENCES usuarios(id_usuario)
);

-- ─── CONFIGURACIÓN del sistema (HU-14: alertas) ──────────────────────
CREATE TABLE configuracion (
  id                     INTEGER PRIMARY KEY DEFAULT 1,
  dias_anticipacion      INTEGER NOT NULL DEFAULT 3 CHECK (dias_anticipacion > 0),
  notificaciones_activas BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT solo_una_fila CHECK (id = 1)
);

-- Índices para acelerar búsquedas frecuentes
CREATE INDEX idx_membresias_socio   ON membresias(id_socio);
CREATE INDEX idx_asistencia_socio   ON asistencia(id_socio);
CREATE INDEX idx_pagos_socio        ON pagos(id_socio);
CREATE INDEX idx_ventas_socio       ON ventas(id_socio);
CREATE INDEX idx_usuarios_correo    ON usuarios(correo);
