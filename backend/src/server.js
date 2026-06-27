import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import cron from 'node-cron';
import { testConnection } from './config/db.js';
import authRoutes from './routes/authRoutes.js';
import sociosRoutes from './routes/sociosRoutes.js';
import planesRoutes from './routes/planesRoutes.js';
import membresiasRoutes from './routes/membresiasRoutes.js';
import asistenciaRoutes from './routes/asistenciaRoutes.js';
import pagosRoutes from './routes/pagosRoutes.js';
import productosRoutes from './routes/productosRoutes.js';
import ventasRoutes from './routes/ventasRoutes.js';
import socioRoutes from './routes/socioRoutes.js';
import reportesRoutes from './routes/reportesRoutes.js';
import notificacionesRoutes from './routes/notificacionesRoutes.js';
import configuracionRoutes from './routes/configuracionRoutes.js';
import { generarNotificacionesVencimiento } from './controllers/notificacionesController.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());

// Ruta de salud — para verificar que la API responde
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'API StanleyGym funcionando 🏋️', timestamp: new Date() });
});

// Rutas de la API
app.use('/api/auth', authRoutes);
app.use('/api/socios', sociosRoutes);
app.use('/api/planes', planesRoutes);
app.use('/api/membresias', membresiasRoutes);
app.use('/api/asistencia', asistenciaRoutes);
app.use('/api/pagos', pagosRoutes);
app.use('/api/productos', productosRoutes);
app.use('/api/ventas', ventasRoutes);
app.use('/api/socio', socioRoutes);
app.use('/api/reportes', reportesRoutes);
app.use('/api/notificaciones', notificacionesRoutes);
app.use('/api/configuracion', configuracionRoutes);

// Manejo de rutas no encontradas
app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

// ─── Cron job: genera notificaciones de vencimiento cada día a las 08:00 ──────
// (sintaxis cron: minuto hora * * *)
cron.schedule('0 8 * * *', async () => {
  try {
    const n = await generarNotificacionesVencimiento();
    console.log(`⏰ [cron] Notificaciones de vencimiento generadas: ${n}`);
  } catch (e) {
    console.error('⏰ [cron] Error generando notificaciones:', e.message);
  }
});

// Iniciar servidor
app.listen(PORT, async () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
  await testConnection();
});
