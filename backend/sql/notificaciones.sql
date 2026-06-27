-- Tabla de notificaciones (HU-05). Cada aviso generado para un socio.
CREATE TABLE IF NOT EXISTS notificaciones (
  id_notificacion SERIAL PRIMARY KEY,
  id_socio        INTEGER NOT NULL REFERENCES socios(id_socio) ON DELETE CASCADE,
  id_membresia    INTEGER REFERENCES membresias(id_membresia) ON DELETE SET NULL,
  titulo          VARCHAR(150) NOT NULL,
  mensaje         TEXT         NOT NULL,
  tipo            VARCHAR(20)  NOT NULL DEFAULT 'vencimiento',
  leida           BOOLEAN      NOT NULL DEFAULT FALSE,
  fecha_creacion  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notif_socio ON notificaciones(id_socio);

ALTER TABLE notificaciones ENABLE ROW LEVEL SECURITY;
