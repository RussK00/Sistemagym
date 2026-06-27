-- Tokens de dispositivos para notificaciones push (FCM) — HU-05 Capa 2.
-- Un socio puede tener varios dispositivos (varios tokens).
CREATE TABLE IF NOT EXISTS tokens_fcm (
  id_token       SERIAL PRIMARY KEY,
  id_socio       INTEGER NOT NULL REFERENCES socios(id_socio) ON DELETE CASCADE,
  token          TEXT    NOT NULL UNIQUE,
  fecha_registro TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tokens_socio ON tokens_fcm(id_socio);

ALTER TABLE tokens_fcm ENABLE ROW LEVEL SECURITY;
