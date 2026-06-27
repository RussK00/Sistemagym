# StalinProGym

Sistema multiplataforma para la gestión integral de un gimnasio: socios,
membresías, asistencia, pagos, productos y reportes, con panel web para el
personal y app móvil para los socios.

## Tecnologías
- Flutter (app móvil + panel web)
- Node.js + Express (backend / API REST)
- PostgreSQL en Supabase (base de datos)

## Características principales

-  **Inicio de sesión por roles**: administrador, recepcionista y socio.
-  **Gestión de socios**: registro, edición y activación/desactivación.
-  **Membresías**: asignación y renovación con validaciones (no duplicar
  una activa, no renovar antes de vencer).
-  **Check-in de asistencia**: registro de ingreso validando membresía vigente.
-  **Pagos**: historial de pagos (se registran al asignar/renovar membresía).
-  **Productos**: catálogo con categorías (suplementos, bebidas, accesorios),
  imágenes y control de stock.
-  **Reportes**: asistencia, membresías por vencer y panel de estadísticas.
-  **App del socio**: consulta de membresía, asistencia y compras.
-  **Configuración**: gestión de recepcionistas y alertas de vencimiento.

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/) (versión 18 o superior)
- Una cuenta de [Supabase](https://supabase.com/) (base de datos)

## Instalación y ejecución

### 1. Clonar el repositorio
```bash
git clone https://github.com/RussK00/Sistemagym.git
cd Sistemagym
```

### 2. Backend (API)
```bash
cd backend
npm install
```
Luego copia `.env.example` a `.env` y completa tus credenciales
(URL de la base de datos, claves de Supabase y JWT). Después:
```bash
npm start
```
La API quedará corriendo en `http://localhost:3000`.

### 3. App / Panel web (Flutter)
En otra terminal:
```bash
cd stanleygym_app
flutter pub get
flutter run -d chrome
```

> ⚠️ El backend y la app deben estar corriendo al mismo tiempo.

## Estructura del proyecto

```
Sistemagym/
├── backend/                → API REST (Node.js + Express)
│   ├── src/
│   │   ├── controllers/    → lógica de cada módulo
│   │   ├── routes/         → rutas de la API
│   │   ├── config/         → conexión a la base de datos
│   │   └── server.js       → punto de entrada
│   └── sql/                → esquema de la base de datos
│
└── stanleygym_app/         → App Flutter (panel web + app móvil)
    └── lib/
        ├── core/           → temas, servicios de API, utilidades
        └── features/       → pantallas por módulo (socios, membresías, etc.)
```
## Capturas de pantalla

### Inicio de sesión
<img width="1917" height="1045" alt="loguin" src="https://github.com/user-attachments/assets/c5b161c5-4bbb-442b-9234-b742ecae6117" />

### Panel del administrador
<img width="1905" height="902" alt="Panel" src="https://github.com/user-attachments/assets/9d136065-eb91-4cae-aec8-382d6e34796a" />

## Autores
- **Fátima Karina Iglesias de Águila — Product Owner**
- **Carrillo de Loayza Luis Alberto — Analista**
- **López Sisley Jesús Abel — Desarrollador**
- **Russel Jhosemith Gálvez Ramírez — Diseñador**

Estudiantes de la Facultad de Ingeniería de Sistemas e Informática — Universidad Nacional de la Amazonía Peruana (UNAP)
2026
