import pkg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pkg;

// Pool de conexiones a PostgreSQL (Supabase).
// Supabase requiere SSL en las conexiones.
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// Helper para ejecutar consultas con parámetros (previene inyección SQL).
export const query = (text, params) => pool.query(text, params);

// Verifica la conexión al iniciar.
export async function testConnection() {
  try {
    const res = await pool.query('SELECT NOW()');
    console.log('✅ Conectado a PostgreSQL (Supabase):', res.rows[0].now);
    return true;
  } catch (err) {
    console.error('❌ Error al conectar a la base de datos:', err.message);
    return false;
  }
}
