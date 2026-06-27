-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Activar Row Level Security (RLS) en todas las tablas.             ║
-- ║                                                                    ║
-- ║  Con RLS activado y SIN políticas, se bloquea todo acceso por la   ║
-- ║  API pública de Supabase (llaves anon/authenticated).             ║
-- ║                                                                    ║
-- ║  Nuestro backend Node.js se conecta con el usuario 'postgres'      ║
-- ║  (superusuario), que IGNORA RLS — por eso sigue funcionando igual. ║
-- ║                                                                    ║
-- ║  Esto cierra la puerta pública sin afectar a nuestra API Express.  ║
-- ╚══════════════════════════════════════════════════════════════════╝

ALTER TABLE socios        ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios      ENABLE ROW LEVEL SECURITY;
ALTER TABLE planes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE membresias    ENABLE ROW LEVEL SECURITY;
ALTER TABLE asistencia    ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos         ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos     ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas        ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracion ENABLE ROW LEVEL SECURITY;
